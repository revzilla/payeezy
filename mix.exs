defmodule Payeezy.Mixfile do
  use Mix.Project

  @version "0.1.3"

  def project do
    [
      app: :payeezy,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      description: description(),
      package: package(),
      name: "Payeezy",
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :poison, :httpoison]]
  end

  defp description do
    """
    Payeezy API library for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["RevZilla", "Tyler Cain", "Steve DeGele"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/revzilla/payeezy"},
      files: ~w(lib mix.exs README.md CHANGELOG.md)
    ]
  end

  defp deps do
    [
      {:poison, "~> 2.1"},
      {:httpoison, "~> 1.1.1"},
      {:bypass, "~> 0.6.0", only: [:test, :dev]},
      {:excoveralls, "~> 0.7", only: :test},
      {:plug, "~> 1.3", only: [:test, :dev]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
