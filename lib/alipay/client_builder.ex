defmodule Alipay.ClientBuilder do
  @moduledoc false

  defmacro __using__(options \\ []) do
    client = __CALLER__.module
    options = check_options!(options, client, __CALLER__)
    requester = Map.get(options, :requester, Alipay.Utils)

    quote do
      @spec get(url :: binary, opts :: keyword) :: WeChat.response()
      def get(url \\ "/gateway.do", opts \\ []) do
        unquote(requester).client(__MODULE__) |> Tesla.get(url, opts)
      end

      @spec post(url :: binary, body :: any, opts :: keyword) :: WeChat.response()
      def post(url \\ "/gateway.do", body, opts \\ []) do
        unquote(requester).client(__MODULE__) |> Tesla.post(url, body, opts)
      end

      def app_id, do: unquote(options.app_id)
      def private_key, do: unquote(options.private_key)
      def public_key, do: unquote(options.public_key)
      def sandbox?, do: unquote(options.sandbox? || false)
    end
  end

  defp check_options!(options, client, caller) do
    options = options |> Macro.prewalk(&Macro.expand(&1, caller)) |> Map.new()

    unless Map.get(options, :app_id) |> is_binary() do
      raise ArgumentError, "Please set app_id option for #{inspect(client)}"
    end

    private_key = transform_pem_file(client, options, :private_key)
    public_key = transform_pem_file(client, options, :public_key)

    options
    |> Map.put(:private_key, Macro.escape(private_key))
    |> Map.put(:public_key, Macro.escape(public_key))
  end

  defp transform_pem_file(client, options, key) do
    case Map.get(options, key) |> transform_pem_file() do
      {:bad_arg, nil} ->
        raise ArgumentError, "Please set #{key} option for #{inspect(client)}"

      {:bad_arg, pem_file} ->
        raise ArgumentError,
              "Bad #{key}: #{inspect(pem_file)} option for #{inspect(client)}"

      {:not_exists, path} ->
        raise ArgumentError,
              "Bad #{key} for #{inspect(client)}, file: #{path} not_exists"

      {:ok, pk} ->
        pk
    end
  end

  def transform_pem_file(quoted = {:{}, opts, list}) when is_list(opts) and is_list(list) do
    {pem_file, _} = Code.eval_quoted(quoted)
    transform_pem_file(pem_file)
  end

  def transform_pem_file({:app_dir, app, path}) when is_atom(app) and is_binary(path) do
    pem_file = Application.app_dir(app, path)
    transform_pem_file({:file, pem_file})
  end

  def transform_pem_file({:file, path}) when is_binary(path) do
    filename = Path.expand(path)

    if File.exists?(filename) do
      binary = File.read!(filename)
      transform_pem_file({:binary, binary})
    else
      {:not_exists, path}
    end
  end

  def transform_pem_file({:binary, binary}) when is_binary(binary) do
    pk = binary |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
    {:ok, pk}
  end

  def transform_pem_file(other), do: {:bad_arg, other}
end
