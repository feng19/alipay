defmodule Alipay do
  @moduledoc """
  Alipay SDK for Elixir

  ## 定义 `Client` 模块

  ### 小程序

      defmodule YourApp.AppCodeName do
        @moduledoc "CodeName"
        use Alipay,
          app_id: "app_id",
          private_key: {:file, "private_key.pem"},
          public_key: {:file, "public_key.pem"}
      end

  ## 参数说明

  请看 `t:options/0`

  ## 接口调用

    `Alipay.Trade.pay(YourApp.AppCodeName, body)`
  """

  @type client :: module()
  @type app_id :: String.t()
  @type pem_file ::
          {:binary, binary} | {:file, Path.t()} | {:app_dir, Application.app(), Path.t()}
  @typedoc "是否是沙盒应用"
  @type sandbox? :: boolean
  @type options :: [
          app_id: app_id,
          private_key: pem_file,
          public_key: pem_file,
          requester: module,
          sandbox?: sandbox?
        ]

  @doc false
  defmacro __using__(options \\ []) do
    quote do
      use Alipay.ClientBuilder, unquote(options)
    end
  end

  @doc "动态构建 client"
  @spec build_client(client, options) :: {:ok, client}
  def build_client(client, options) do
    with {:module, module, _binary, _term} <-
           Module.create(
             client,
             quote do
               @moduledoc false
               use Alipay.ClientBuilder, unquote(Macro.escape(options))
             end,
             Macro.Env.location(__ENV__)
           ) do
      {:ok, module}
    end
  end
end
