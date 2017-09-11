defmodule Absinthe.Phoenix.ControllerTest do
  use ExUnit.Case, async: true
  use Absinthe.Phoenix.ConnCase

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :string, :string do
        arg :echo, :string
        resolve &resolve_echo/3
      end
      field :integer, :integer do
        arg :echo, :integer
        resolve &resolve_echo/3
      end
      field :list_of_integers, list_of(:integer) do
        arg :echo, list_of(:integer)
        resolve &resolve_echo/3
      end

    end

    def resolve_echo(_, %{echo: echo}, _) do
      {:ok, echo}
    end

  end

  defmodule Controller do
    use Phoenix.Controller
    use Absinthe.Phoenix.Controller, schema: Absinthe.Phoenix.ControllerTest.Schema

    @graphql """
    query ($echo: String) { string(echo: $echo) }
    """
    def string(conn, %{data: data}), do: json(conn, data)

    @graphql """
    query ($echo: Int) { integer(echo: $echo) }
    """
    def integer(conn, %{data: data}), do: json(conn, data)

    @graphql """
    query ($echo: [Int]) { list_of_integers(echo: $echo) }
    """
    def list_of_integers(conn, %{data: data}), do: json(conn, data)

  end

  describe "input" do
    test "string" do
      assert %{"string" => "one"} == result(Controller, :string, %{"echo" => "one"})
    end
    test "integer" do
      assert %{"integer" => 1} == result(Controller, :integer, %{"echo" => "1"})
    end
    test "list of integers" do
      assert %{"list_of_integers" => [1, 2, 3]} == result(Controller, :list_of_integers, %{"echo" => ~w(1 2 3)})
    end
  end

  def result(controller, name, params, verb \\ :get) do
    conn = build_conn(verb, "/", params) |> Plug.Conn.fetch_query_params
    controller.call(conn, controller.init(name))
    |> json_response(200)
  end

end
