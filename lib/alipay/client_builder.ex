defmodule Alipay.ClientBuilder do
  @moduledoc false

  defmacro __using__(options \\ []) do
    client = __CALLER__.module
    options = check_options!(options, client, __CALLER__)
    requester = Map.get(options, :requester, Alipay.Requester)

    quote do
      @spec get(url :: binary, opts :: keyword) :: Alipay.response()
      def get(url, opts \\ []), do: unquote(requester).get(__MODULE__, url, opts)
      @spec post(url :: binary, body :: any, opts :: keyword) :: Alipay.response()
      def post(url, body, opts \\ []), do: unquote(requester).post(__MODULE__, url, body, opts)
      def app_id, do: unquote(options.app_id)
      @doc false
      def private_key, do: unquote(options.private_key)
      @doc false
      def callback_public_key, do: unquote(options.callback_public_key)
      def sandbox?, do: unquote(options.sandbox? || false)
      unquote(gen_aes_key(options))
    end
  end

  defp check_options!(options, client, caller) do
    options = Macro.prewalk(options, &Macro.expand(&1, caller))
    options = Keyword.merge([sandbox?: false], options) |> Map.new()

    if !(Map.get(options, :app_id) |> is_binary()) do
      raise ArgumentError, "Please set app_id option for #{inspect(client)}"
    end

    private_key = transform_pem_file(client, options, :private_key)

    callback_public_key =
      if options[:callback_public_key] do
        transform_pem_file(client, options, :callback_public_key)
      else
        nil
      end

    options
    |> Map.put(:private_key, Macro.escape(private_key))
    |> Map.put(:callback_public_key, Macro.escape(callback_public_key))
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

  defp gen_aes_key(options) do
    if aes_key = options[:aes_key] do
      aes_key = Base.decode64!(aes_key)

      quote do
        def aes_key, do: unquote(aes_key)
      end
    end
  end
end
