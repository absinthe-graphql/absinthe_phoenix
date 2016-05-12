defmodule Absinthe.Phoenix.TestRouter do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipe_through :api

  get "/:id", Absinthe.Phoenix.TestController, :get
  get "/", Absinthe.Phoenix.TestController, :index
end
