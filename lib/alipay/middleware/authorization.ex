defmodule Alipay.Middleware.Authorization do
  @moduledoc false
  @behaviour Tesla.Middleware
  alias Alipay.Crypto

  @impl Tesla.Middleware
  def call(env, next, client) do
    env =
      case env.body do
        nil -> ""
        "" -> ""
        body when is_map(body) -> Jason.encode!(body)
        body when is_list(body) -> Jason.encode!(body)
      end
      |> then(&Tesla.put_body(env, &1))

    nonce = :crypto.strong_rand_bytes(24) |> Base.url_encode64()

    auth_string =
      "app_id=#{client.app_id()},nonce=#{nonce},timestamp=#{Alipay.Utils.now_unix_mill()}"

    signature = Crypto.v3_sign(env, auth_string, client.private_key())
    authorization = "ALIPAY-SHA256withRSA #{auth_string},sign=#{signature}"

    env
    |> Tesla.put_headers([
      {"authorization", authorization},
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ])
    |> Tesla.run(next)
  end
end
