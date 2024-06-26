if Code.ensure_loaded?(Plug) do
  defmodule Alipay.Plug.EventHandler do
    @moduledoc """
    异步通知处理器

    [异步通知说明](https://opendocs.alipay.com/open-v3/05pf4k)

    - 在进行异步通知交互时，如果支付宝收到的应答不是 `success` ，支付宝会认为通知失败，会通过一定的策略定期重新发起通知。
    重试逻辑为：当未收到 `success` 时立即尝试重发 3 次通知，若 3 次仍不成功，则后续通知的间隔频率为：4m、10m、10m、1h、2h、6h、15h。
    - 商家设置的异步地址（`notify_url`）需保证无任何字符，如空格、HTML 标签，且不能重定向。
    （如果重定向，支付宝会收不到 `success` 字符，会被支付宝服务器判定为该页面程序运行出现异常，而重发处理结果通知）
    - 支付宝针对同一条异步通知重试时，异步通知参数中的 `notify_id` 是不变的。

    ## Usage

    将下面的代码加到 `router` 里面：

    - 单一应用的情况：

        forward "/ali/event", #{inspect(__MODULE__)},
          client: YourApp.AppCodeName,
          event_handler: &YourModule.handle_event/2

    - 多个应用的情况：

      请将入口路径设置为如下格式: `/*xxx/:app`

          scope "/ali/event/:app" do
            post "/", #{inspect(__MODULE__)},
              client: &YourModule.get_client_by_app/1,
              event_handler: &YourModule.handle_event/2
          end

      before phoenix 1.17:

          scope "/ali/event/:app" do
            forward "/", #{inspect(__MODULE__)},
              client: &YourModule.get_client_by_app/1,
              event_handler: &YourModule.handle_event/2
          end

    ## Options

    - `event_handler`: 必填, [定义](`t:event_handler/0`)
    - `client`: 必填, [Client](`t:Alipay.client/0`) | [function](`t:get_client_fun/0`)
    """

    import Plug.Conn
    require Logger
    alias Alipay.Crypto
    @behaviour Plug

    @typedoc """
    事件处理回调返回值

    返回值说明：
    - `:ok`: 成功
    - `:ignore`: 成功
    - `:retry`: 选择重试，支付宝服务器会重试三次
    - `:error`: 返回错误，支付宝服务器会重试三次
    - `{:error, any}`: 返回错误，支付宝服务器会重试三次
    """
    @type event_handler_return ::
            {:reply, reply_msg :: EventHelper.json_string()}
            | :ok
            | :ignore
            | :retry
            | :error
            | {:error, any}
            | Plug.Conn.t()
    @typedoc "事件处理回调函数"
    @type event_handler :: (Plug.Conn.t(), Alipay.client() -> event_handler_return)
    @typedoc "通过 app 获取 client 函数"
    @type get_client_fun :: (app :: String.t() -> Alipay.client() | nil)

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      event_handler =
        with {:ok, handler} <- Map.fetch(opts, :event_handler),
             true <- is_function(handler, 2) do
          handler
        else
          :error ->
            raise ArgumentError, "please set :event_handler when using #{inspect(__MODULE__)}"

          false ->
            raise ArgumentError,
                  "the :event_handler must arg 2 function when using #{inspect(__MODULE__)}"
        end

      case Map.fetch(opts, :client) do
        {:ok, client} when is_atom(client) ->
          if client.callback_public_key() != nil do
            %{event_handler: event_handler, client: client}
          else
            raise ArgumentError,
                  "please set :callback_public_key when defining #{inspect(client)}"
          end

        {:ok, get_client} when is_function(get_client, 1) ->
          %{event_handler: event_handler, get_client: get_client}

        _ ->
          raise ArgumentError, "please set :client when using #{inspect(__MODULE__)}"
      end
    end

    @doc false
    def call(%{method: "POST", body_params: params} = conn, %{
          client: client,
          event_handler: event_handler
        }) do
      if Crypto.verify_callback(params, client.callback_public_key()) do
        try do
          event_handler.(conn, client)
        rescue
          error ->
            Logger.error(
              "call #{inspect(event_handler)}.(#{inspect(client)}) get error: #{inspect(error)}"
            )

            send_resp(conn, 500, "Internal Server Error")
        else
          :retry ->
            send_resp(conn, 500, "please retry")

          :error ->
            send_resp(conn, 500, "error, please retry")

          {:error, _} ->
            send_resp(conn, 500, "error, please retry")

          :ok ->
            send_resp(conn, 200, "success")

          :ignore ->
            send_resp(conn, 200, "success")

          conn ->
            conn
        end
      else
        send_resp(conn, 400, "Bad Request")
      end
      |> halt()
    end

    def call(%{method: "POST", path_params: path_params} = conn, %{
          get_client: get_client,
          event_handler: event_handler
        }) do
      with app <- path_params["app"],
           client when client != nil <- get_client.(app) do
        call(conn, %{client: client, event_handler: event_handler})
      else
        _ -> send_resp(conn, 400, "Bad Request") |> halt()
      end
    end

    def call(conn, _opts) do
      send_resp(conn, 404, "Invalid Method") |> halt()
    end
  end
end
