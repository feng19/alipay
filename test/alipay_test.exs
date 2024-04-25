defmodule AlipayTest do
  use ExUnit.Case
  alias Alipay.TestClient

  test "Auto generate functions(Pay)" do
    assert TestClient.app_id() == "2024000000000001"
    assert TestClient.sandbox?() == false
    assert function_exported?(TestClient, :private_key, 0)
    assert function_exported?(TestClient, :callback_public_key, 0)
    assert true = Enum.all?(1..2, &function_exported?(TestClient, :get, &1))
    assert true = Enum.all?(2..3, &function_exported?(TestClient, :post, &1))
  end
end
