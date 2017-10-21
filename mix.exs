defmodule Absinthe.Phoenix.Mixfile do
  use Mix.Project

  def project do
    [app: :absinthe_phoenix,
     version: "1.4.0-rc.3",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps()]
  end

  defp package do
    [description: "Subscription support via Phoenix for Absinthe, the GraphQL implementation for Elixir.",
     files: ["lib", "mix.exs", "README*"],
     maintainers: ["Ben Wilson", "Bruce Williams"],
     licenses: ["MIT"],
     links: %{
       site: "http://absinthe-graphql.org",
       github: "https://github.com/absinthe-graphql/absinthe_phoenix",
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:absinthe_plug, "~> 1.4.0-rc"},
      # {:absinthe, "~> 1.4.0-rc.2"},
      {:absinthe, github: "absinthe-graphql/absinthe", override: true},
      {:decimal, "~> 1.0"},
      {:phoenix, "~> 1.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:poison, "~> 2.0 or ~> 3.0"},
    ]
  end
end
