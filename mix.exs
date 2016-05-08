defmodule Absinthe.Phoenix.Mixfile do
  use Mix.Project

  def project do
    [app: :absinthe_phoenix,
     version: "0.0.1",
     elixir: "~> 1.3-dev",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: [:logger, :absinthe, :phoenix]]
  end

  defp deps do
    [
      {:absinthe, "~> 1.1"},
      {:phoenix, "~> 1.0"},
      {:poison, "~> 2.0"},
    ]
  end
end
