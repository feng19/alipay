defmodule Alipay.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config = Application.get_all_env(:alipay) |> normalize()

    children = [
      {Finch, name: Alipay.Finch, pools: %{:default => config[:finch_pool]}}
    ]

    opts = [strategy: :one_for_one, name: Alipay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp normalize(config) do
    Keyword.merge(
      [
        finch_pool: [size: 32, count: 8]
      ],
      config
    )
  end
end
