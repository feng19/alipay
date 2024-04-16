defmodule Alipay.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/feng19/alipay"

  def project do
    [
      app: :alipay,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Alipay.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.9"},
      {:jason, "~> 1.2"},
      {:plug, "~> 1.11", optional: true},
      {:ex_doc, ">= 0.0.0", only: [:docs, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "master",
      formatters: ["html"],
      formatter_opts: [gfm: true]
    ]
  end

  defp package do
    [
      name: "alipay_sdk",
      description: "Alipay SDK for Elixir",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["feng19"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
