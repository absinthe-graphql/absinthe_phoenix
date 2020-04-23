use Mix.Config

config :logger, level: :warn

config :absinthe_phoenix, Absinthe.Phoenix.TestEndpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "GSGmIoMRxcLfHBfBhtD/Powy7WaucKbLuB7BTMt41nkm5xS+8LfnXZYNsk6qKOo1",
  render_errors: [accepts: ~w(json)],
  pubsub_server: Absinthe.Phoenix.PubSub
