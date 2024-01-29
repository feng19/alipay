defmodule Alipay.Trade do
  @moduledoc false

  def pre_create(client, body) do
    client.post("v3/alipay/trade/precreate", body)
  end

  def create(client, body) do
    client.post("v3/alipay/trade/create", body)
  end

  def pay(client, body) do
    client.post("v3/alipay/trade/pay", body)
  end

  def query(client, body) do
    client.post("v3/alipay/trade/query", body)
  end

  def refund(client, body) do
    client.post("v3/alipay/trade/refund", body)
  end

  def query_refund(client, body) do
    client.post("v3/alipay/trade/fastpay/refund/query", body)
  end

  def cancel(client, body) do
    client.post("v3/alipay/trade/cancel", body)
  end

  def close(client, body) do
    client.post("v3/alipay/trade/close", body)
  end

  def fetch_bill_download_url(client, body) do
    client.post("v3/alipay/data/dataservice/bill/downloadurl/query", body)
  end
end
