defmodule Absinthe.Phoenix.SubscriptionTestTest do
  use ExUnit.Case
  use Absinthe.Phoenix.ChannelCase
  import Absinthe.Phoenix.SubscriptionTest

  setup_all do
    Absinthe.Test.prime(Schema)

    children = [
      {Phoenix.PubSub, [name: Absinthe.Phoenix.PubSub, adapter: Phoenix.PubSub.PG2]},
      Absinthe.Phoenix.TestEndpoint,
      {Absinthe.Subscription, Absinthe.Phoenix.TestEndpoint}
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    :ok
  end

  test "subscription can be started and its' updates can be asserted" do
    socket = build_socket(Absinthe.Phoenix.TestEndpoint, Absinthe.Phoenix.TestSocket)

    subscription_id = start_subscription(socket, "subscription {commentAdded { contents }}")

    ref =
      push(socket, "doc", %{
        "query" => "mutation ($contents: String!) {addComment(contents: $contents) { contents }}",
        "variables" => %{"contents" => "hello world"}
      })

    assert_reply(ref, :ok, reply)

    expected = %{data: %{"addComment" => %{"contents" => "hello world"}}}
    assert expected == reply

    assert_subscription_update(subscription_id, %{
      "commentAdded" => %{"contents" => "hello world"}
    })

    refute_subscription_update(subscription_id)
  end
end
