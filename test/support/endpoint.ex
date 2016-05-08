defmodule Absinthe.Phoenix.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :absinthe_phoenix

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Absinthe.Phoenix.TestRouter
end
