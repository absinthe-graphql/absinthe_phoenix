use Mix.Config

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
