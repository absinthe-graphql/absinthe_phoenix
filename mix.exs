defmodule Absinthe.Phoenix.Mixfile do
  use Mix.Project

  @version "1.4.4"

  def project do
    [
      app: :absinthe_phoenix,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [source_ref: "v#{@version}"],
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      description:
        "Subscription support via Phoenix for Absinthe, the GraphQL implementation for Elixir.",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Ben Wilson", "Bruce Williams"],
      licenses: ["MIT"],
      links: %{
        Website: "https://absinthe-graphql.org",
        Changelog:
          "https://github.com/absinthe-graphql/absinthe_phoenix/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/absinthe-graphql/absinthe_phoenix"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe, "~> 1.4.0"},
      {:decimal, "~> 1.0"},
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.13", optional: true},
      {:ex_doc, "~> 0.14", only: :dev},
      {:jason, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
