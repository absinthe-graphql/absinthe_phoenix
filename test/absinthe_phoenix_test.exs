defmodule Absinthe.PhoenixTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  @endpoint Absinthe.Phoenix.TestEndpoint

  setup_all do
    {:ok, _} = Absinthe.Phoenix.TestEndpoint.start_link
    :ok
  end

  test "It works" do
    conn =
      conn()
      |> put_req_header("content-type", "application/json")
      |> get("/", %{foo: "bar"})

    params = conn.assigns.params

    assert %{foo: "bar"} == params
  end
end
