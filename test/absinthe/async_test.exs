defmodule Absinthe.AsyncTest do
  use ExUnit.Case
  use Absinthe.Phoenix.ChannelCase

  setup_all do
    Absinthe.Test.prime(Schema)

    {:ok, _} = Absinthe.Phoenix.TestEndpoint.start_link()
    {:ok, _} = Absinthe.Subscription.start_link(Absinthe.Phoenix.TestEndpoint)
    :ok
  end

  test "defer sync" do
    socket = get_socket(0)
    query = %{"query" => "query { slow_field (delay: 400) { value @defer } }"}
    ref = push(socket, "doc", query)
    refute_reply(ref, _, _, 200)

    query = %{"query" => "query { slow_field (delay: 100) { value @defer } }"}
    ref2 = push(socket, "doc", query)

    # This second query will be blocked by the first because there are no async
    # threads left to handle it
    assert_reply(ref, :ok, %{queryId: id1}, 500)
    assert_push("doc", reply)
    assert reply.queryId == id1
    assert reply.data == 400

    assert_reply(ref2, :ok, %{queryId: id2}, 200)
    assert_push("doc", reply)
    assert reply.queryId == id2
    assert reply.data == 100
  end

  test "repeated async defers" do
    socket = get_socket(2)

    # Run the test multiple times to ensure that completed async tasks are
    # cleaned up and don't prevent subsequent queries being handled
    # asynchronously
    Enum.each(1..3, fn _ ->
      query = %{"query" => "query { slow_field (delay: 400) { value @defer } }"}
      ref = push(socket, "doc", query)
      assert_reply(ref, :ok, %{queryId: id1})

      query = %{"query" => "query { slow_field (delay: 100) { value @defer } }"}
      ref = push(socket, "doc", query)
      assert_reply(ref, :ok, %{queryId: id2})

      # This second query is faster so its deferred result should arrive before
      # the first query's
      assert_push("doc", reply, 200)
      assert reply.queryId == id2
      assert reply.data == 100

      assert_push("doc", reply, 400)
      assert reply.queryId == id1
      assert reply.data == 400
    end)
  end

  defp get_socket(max_async_procs) do
    {:ok, _, socket} =
      "asdf"
      |> socket(
        absinthe: %{schema: Schema, opts: []},
        max_async_procs: max_async_procs
      )
      |> subscribe_and_join(Absinthe.Phoenix.Channel, "__absinthe__:control")

    socket
  end
end
