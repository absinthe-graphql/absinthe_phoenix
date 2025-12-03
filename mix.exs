defmodule Absinthe.Phoenix.Mixfile do
  use Mix.Project

  @source_url "https://github.com/absinthe-graphql/absinthe_phoenix"
  @version "2.0.4"

  def project do
    [
      app: :absinthe_phoenix,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp package do
    [
      description:
        "Subscription support via Phoenix for Absinthe, the GraphQL implementation for Elixir.",
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "CODE_OF_CONDUCT.md",
        "LICENSE.md"
      ],
      maintainers: ["Ben Wilson", "Bruce Williams"],
      licenses: ["MIT"],
      links: %{
        Website: "https://absinthe-graphql.org",
        Changelog: "https://hexdocs.pm/absinthe_phoenix/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:absinthe_plug, "~> 1.5"},
      {:absinthe, "~> 1.5"},
      {:decimal, "~> 1.0 or ~> 2.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.13 or ~> 3.0 or ~> 4.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "CODE_OF_CONDUCT.md",
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
