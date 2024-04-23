defmodule Alipay.Requester do
  @moduledoc "默认的请求客户端"
  alias Tesla.Middleware

  @opts Application.compile_env(:alipay, __MODULE__, [])

  if Mix.env() == :test do
    @adapter Tesla.Mock
  else
    @adapter_options @opts
                     |> Keyword.get(:adapter_options, pool_timeout: 5_000, receive_timeout: 5_000)
                     |> Keyword.put(:name, Alipay.Finch)
    @adapter {Tesla.Adapter.Finch, @adapter_options}
  end

  @retry_options Keyword.get(@opts, :retry_options,
                   delay: 500,
                   max_retries: 3,
                   max_delay: 2_000,
                   should_retry: &__MODULE__.request_should_retry/1
                 )

  @spec get(Alipay.client(), url :: binary, opts :: keyword) :: Alipay.response()
  def get(client, url, opts \\ []) do
    client |> http_client() |> Tesla.get(url, opts)
  end

  @spec post(Alipay.client(), url :: binary, body :: any, opts :: keyword) :: Alipay.response()
  def post(client, url, body, opts \\ []) do
    client |> http_client() |> Tesla.post(url, body, opts)
  end

  def http_client(client) do
    base_url =
      if client.sandbox?() do
        "https://openapi-sandbox.dl.alipaydev.com"
      else
        "https://openapi.alipay.com"
      end

    Tesla.client(
      [
        {Middleware.BaseUrl, base_url},
        {Alipay.Middleware.Authorization, client},
        {Alipay.Middleware.VerifySignature, client},
        {Tesla.Middleware.Retry, @retry_options},
        Middleware.Logger
      ],
      @adapter
    )
  end

  def request_should_retry({:ok, %{status: status}}) when status in [400, 500], do: true
  def request_should_retry({:ok, _}), do: false
  def request_should_retry({:error, _}), do: true
end
