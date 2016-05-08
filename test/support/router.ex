defmodule Absinthe.Phoenix.TestRouter do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipe_through :api

  get "/", Absinthe.Phoenix.TestController, :index
end
