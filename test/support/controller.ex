defmodule Absinthe.Phoenix.TestController do
  use Phoenix.Controller
  use Absinthe.Phoenix

  input_object :index do
    field :name, non_null(:string)
    field :age, :integer
  end

  def index(conn, params) do
    conn
    |> assign(:params, params)
  end
end
