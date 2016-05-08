defmodule Absinthe.Phoenix.TestController do
  use Phoenix.Controller

  def index(conn, params) do
    conn
    |> assign(:params, params)
  end
end
