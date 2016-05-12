defmodule Absinthe.PhoenixTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  @endpoint Absinthe.Phoenix.TestEndpoint

  setup_all do
    {:ok, _} = Absinthe.Phoenix.TestEndpoint.start_link
    :ok
  end

  test "basic test" do
    conn =
      conn()
      |> put_req_header("content-type", "application/json")
      |> get("/", %{name: "bar"})

    assert %{name: "bar"} == conn.assigns.params
  end

  test "it ignores extra values" do
    conn =
      conn()
      |> put_req_header("content-type", "application/json")
      |> get("/", %{name: "bar", buz: "buzz"})

    assert %{name: "bar"} == conn.assigns.params
  end

  test "it errors when non null values are not sent" do
    conn =
      conn()
      |> put_req_header("content-type", "application/json")
      |> get("/", %{})

    assert 400 = conn.status
  end

  test "it doesn't blow up on actions without specified inputs" do
    conn =
      conn()
      |> put_req_header("content-type", "application/json")
      |> get("/1", %{})

    assert %{"id" => "1"} == conn.assigns.params
  end
end
