defmodule Alipay.Middleware.Decrypter do
  @moduledoc false
  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, client) do
    case Tesla.run(env, next) do
      {:ok, %{body: body} = env} when is_map(body) ->
        with {:ok, body} <- Alipay.Crypto.decode_response(body, client.aes_key) do
          {:ok, Tesla.put_body(env, body)}
        end

      error ->
        error
    end
  end
end
