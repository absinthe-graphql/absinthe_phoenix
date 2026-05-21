defmodule Absinthe.Phoenix.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :absinthe_phoenix
  use Absinthe.Phoenix.Endpoint

  socket("/socket", Absinthe.Phoenix.TestSocket)

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
end
