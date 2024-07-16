defmodule Alipay.Trade do
  @moduledoc "交易接口"

  @doc """
  统一收单线下交易预创建 -
  [官方文档](https://opendocs.alipay.com/open-v3/fa0c2141_alipay.trade.precreate){:target="_blank"}

  收银员通过收银台或商户后台调用支付宝接口，生成二维码后，展示给用户，由用户扫描二维码完成订单支付。\n
  注意：预下单请求生成的二维码有效时间为2小时
  """
  @spec pre_create(Alipay.client(), Alipay.body()) :: Alipay.response()
  def pre_create(client, body) do
    client.post("/v3/alipay/trade/precreate", body)
  end

  @doc """
  统一收单交易创建接口 -
  [官方文档](https://opendocs.alipay.com/open-v3/bf4eae5e_alipay.trade.create){:target="_blank"}

  商户通过该接口进行交易的创建下单
  """
  @spec create(Alipay.client(), Alipay.body()) :: Alipay.response()
  def create(client, body) do
    client.post("/v3/alipay/trade/create", body)
  end

  @doc """
  统一收单交易支付接口 -
  [官方文档](https://opendocs.alipay.com/open-v3/08c7f9f8_alipay.trade.pay){:target="_blank"}

  收银员使用扫码设备读取用户手机支付宝“付款码”获取设备（如扫码枪）读取用户手机支付宝的付款码信息后，
  将二维码或条码信息通过本接口上送至支付宝发起支付。
  """
  @spec pay(Alipay.client(), Alipay.body()) :: Alipay.response()
  def pay(client, body) do
    client.post("/v3/alipay/trade/pay", body)
  end

  @doc """
  统一收单交易查询 -
  [官方文档](https://opendocs.alipay.com/open-v3/cbe8826d_alipay.trade.query){:target="_blank"}

  该接口提供所有支付宝支付订单的查询，商户可以通过该接口主动查询订单状态，完成下一步的业务逻辑。
  需要调用查询接口的情况： 当商户后台、网络、服务器等出现异常，商户系统最终未接收到支付通知；
  调用支付接口后，返回系统错误或未知交易状态情况； 调用alipay.trade.pay，返回INPROCESS的状态；
  调用alipay.trade.cancel之前，需确认支付状态
  """
  @spec query(Alipay.client(), Alipay.body()) :: Alipay.response()
  def query(client, body) do
    client.post("/v3/alipay/trade/query", body)
  end

  @doc """
  统一收单交易退款接口 -
  [官方文档](https://opendocs.alipay.com/open-v3/6b16d4a2_alipay.trade.refund){:target="_blank"}

  当交易发生之后一段时间内，由于买家或者卖家的原因需要退款时，卖家可以通过退款接口将支付款退还给买家，
  支付宝将在收到退款请求并且验证成功之后，按照退款规则将支付款按原路退到买家帐号上。\n
  交易超过约定时间（签约时设置的可退款时间）的订单无法进行退款。\n
  支付宝退款支持单笔交易分多次退款，多次退款需要提交原支付订单的订单号和设置不同的退款请求号。
  一笔退款失败后重新提交，要保证重试时退款请求号不能变更，防止该笔交易重复退款。
  同一笔交易累计提交的退款金额不能超过原始交易总金额。
  """
  @spec refund(Alipay.client(), Alipay.body()) :: Alipay.response()
  def refund(client, body) do
    client.post("/v3/alipay/trade/refund", body)
  end

  @doc """
  统一收单交易退款查询 -
  [官方文档](https://opendocs.alipay.com/open-v3/b9ef37bd_alipay.trade.fastpay.refund.query){:target="_blank"}

  商户可使用该接口查询自已通过alipay.trade.refund提交的退款请求是否执行成功。
  """
  @spec query_refund(Alipay.client(), Alipay.body()) :: Alipay.response()
  def query_refund(client, body) do
    client.post("/v3/alipay/trade/fastpay/refund/query", body)
  end

  @doc """
  统一收单交易撤销接口 -
  [官方文档](https://opendocs.alipay.com/open-v3/cd7d54d2_alipay.trade.cancel){:target="_blank"}

  支付交易返回失败或支付系统超时，调用该接口撤销交易。如果此订单用户支付失败，支付宝系统会将此订单关闭；
  如果用户支付成功，支付宝系统会将此订单资金退还给用户。\n
  注意：只有发生支付系统超时或者支付结果未知时可调用撤销，其他正常支付的单如需实现相同功能请调用申请退款API。
  提交支付交易后调用【查询订单API】，没有明确的支付结果再调用【撤销订单API】。
  """
  @spec cancel(Alipay.client(), Alipay.body()) :: Alipay.response()
  def cancel(client, body) do
    client.post("/v3/alipay/trade/cancel", body)
  end

  @doc """
  统一收单交易关闭接口 -
  [官方文档](https://opendocs.alipay.com/open-v3/48ea518b_alipay.trade.close){:target="_blank"}

  用于交易创建后，用户在一定时间内未进行支付，可调用该接口直接将未付款的交易进行关闭。
  """
  @spec close(Alipay.client(), Alipay.body()) :: Alipay.response()
  def close(client, body) do
    client.post("/v3/alipay/trade/close", body)
  end

  @doc """
  查询对账单下载地址 -
  [官方文档](https://opendocs.alipay.com/open-v3/c8d608d7_alipay.data.dataservice.bill.downloadurl.query){:target="_blank"}

  为方便商户快速查账，支持商户通过本接口获取商户离线账单下载地址
  """
  @spec fetch_bill_download_url(Alipay.client(), Alipay.queries()) :: Alipay.response()
  def fetch_bill_download_url(client, queries) do
    client.get("/v3/alipay/data/dataservice/bill/downloadurl/query", query: queries)
  end
end
