defmodule Absinthe.Phoenix.TestController do
  use Phoenix.Controller
  use Absinthe.Phoenix

  input_object :index do
    field :organization_id, list_of(:id)
    field :name, non_null(:string)
  end

  def index(conn, params) do
    conn
    |> assign(:params, params)
  end
end
