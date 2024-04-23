defmodule Alipay.Middleware.VerifySignature do
  @moduledoc false
  @behaviour Tesla.Middleware
  alias Alipay.Crypto

  @impl Tesla.Middleware
  def call(env, next, client) do
    case Tesla.run(env, next) do
      {:ok, %{body: body} = env} when is_binary(body) ->
        with nonce when is_binary(nonce) <- Tesla.get_header(env, "alipay-nonce"),
             signature when is_binary(signature) <- Tesla.get_header(env, "alipay-signature"),
             timestamp when is_binary(timestamp) <- Tesla.get_header(env, "alipay-timestamp"),
             true <- Crypto.verify(signature, timestamp, nonce, body, client.callback_public_key()) do
          Tesla.Middleware.JSON.decode(env, [])
        else
          _error -> {:error, :invaild_response}
        end

      {:ok, %{body: body} = env} when is_binary(body) ->
        Tesla.Middleware.JSON.decode(env, [])

      error ->
        error
    end
  end
end
