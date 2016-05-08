defmodule Absinthe.Phoenix.TestController do
  use Phoenix.Controller
  use Absinthe.Phoenix

  query do
    field :foo, :integer
  end

  def index(conn, params) do
    conn
    |> assign(:params, params)
  end
end
