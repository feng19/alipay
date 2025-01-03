defmodule Alipay.Crypto do
  @moduledoc """
  加解密模块

  ## For V2 Apis
  - [接口加签方式说明](https://opendocs.alipay.com/common/02kf5p)
  - [签名规则](https://opendocs.alipay.com/common/057k53)
  - [验签规则](https://opendocs.alipay.com/common/02mse7)

  ## For V3 Apis
  - [接口加签方式说明](https://opendocs.alipay.com/open-v3/05419m)
  - [签名规则](https://opendocs.alipay.com/open-v3/054q58)
  - [验签规则](https://opendocs.alipay.com/open-v3/054d0z)
  """

  @aes_block_size 16

  def v2_sign(params, private_key) do
    string =
      params
      |> Enum.reject(&(match?({_k, nil}, &1) or match?({_k, ""}, &1)))
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn
        {k, v} when is_map(v) -> "#{k}=#{Jason.encode!(v)}"
        {k, v} -> "#{k}=#{v}"
      end)
      |> Enum.join("&")

    string
    |> :public_key.sign(:sha256, private_key)
    |> Base.encode64()
  end

  def v3_sign(
        %{method: method, url: url, query: query, body: body},
        auth_string,
        private_key
      )
      when is_binary(body) do
    method = method |> to_string() |> String.upcase()

    url =
      case URI.parse(url) do
        %{path: path, query: nil} ->
          path_join_query(path, query)

        %{path: path, query: url_query} ->
          case query do
            [] ->
              path_join_query(path, url_query)

            _ ->
              URI.decode_query(url_query)
              |> Map.merge(Map.new(query))
              |> URI.encode_query()
              |> then(&path_join_query(path, &1))
          end
      end

    "#{auth_string}\n#{method}\n#{url}\n#{body}\n"
    |> :public_key.sign(:sha256, private_key)
    |> Base.encode64()
  end

  defp path_join_query(path, []), do: path
  defp path_join_query(path, ""), do: path

  defp path_join_query(path, query) when is_list(query),
    do: path <> "?" <> URI.encode_query(query)

  defp path_join_query(path, query), do: path <> "?" <> query

  # v3
  def verify(signature, timestamp, nonce, body, public_key) do
    case Base.decode64(signature, padding: false) do
      {:ok, signature} ->
        :public_key.verify("#{timestamp}\n#{nonce}\n#{body}\n", :sha256, signature, public_key)

      _ ->
        false
    end
  end

  def verify_callback(params, public_key) do
    with {"RSA2", params} <- Map.pop(params, "sign_type"),
         {sign, params} when not is_nil(sign) <- Map.pop(params, "sign"),
         {:ok, signature} <- Base.decode64(sign, padding: false) do
      params
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn
        {k, v} when is_map(v) -> "#{k}=#{Jason.encode!(v)}"
        {k, v} -> "#{k}=#{v}"
      end)
      |> Enum.join("&")
      |> :public_key.verify(:sha256, signature, public_key)
    else
      # bad_request
      _ -> false
    end
  end

  # https://opendocs.alipay.com/common/02mse3?pathHash=16b6b087
  def decode_response(%{"encrypt_type" => "AES", "response" => response}, aes_key) do
    response
    |> Base.decode64!()
    |> decrypt_with_aes_cbc(aes_key)
    |> Jason.decode()
  end

  def decode_response(body, _aes_key), do: {:ok, body}

  def encrypt_biz_content(content, aes_key) do
    {:ok, encrypt_with_aes_cbc(content, aes_key)}
  end

  @compile {:inline, encrypt_with_aes_cbc: 2, decrypt_with_aes_cbc: 2}
  defp encrypt_with_aes_cbc(plain_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, plain_text, true)
  end

  defp decrypt_with_aes_cbc(cipher_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, cipher_text, false)
  end
end
