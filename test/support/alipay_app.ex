defmodule Alipay.TestClient do
  @moduledoc "client for alipay"
  use Alipay,
    app_id: "2024000000000001",
    private_key: {:file, "test/support/cert/private.key"},
    callback_public_key: {:file, "test/support/cert/alipay_callback.pub"}
end
