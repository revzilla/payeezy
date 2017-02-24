defmodule Payeezy.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :payeezy,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:bypass, "~> 0.6.0", only: :test},
    ]
  end

  defp version_with_git_revision(version) do
    "#{version}+#{get_revision}"
  end

  defp get_revision do
    git_sha = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    git_sha
    |> elem(0)
    |> String.rstrip
  end
end
