defmodule Absinthe.PhoenixTest do
  use ExUnit.Case, async: true
  use Absinthe.Phoenix.ChannelCase

  setup_all do
    Absinthe.Test.prime(Schema)

    {:ok, _} = Absinthe.Phoenix.TestEndpoint.start_link
    {:ok, _} = Absinthe.Subscriptions.Manager.start_link(Absinthe.Phoenix.TestEndpoint)
    :ok
  end

  setup do
    {:ok, _, socket} =
      socket("asdf", absinthe: %{schema: Schema, opts: [context: %{__absinthe__: [pubsub: Absinthe.Phoenix.TestEndpoint]}]})
      |> subscribe_and_join(Absinthe.Phoenix.Channel, "__absinthe__:control")

    {:ok, socket: socket}
  end

  test "basic query works", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "{users { name }}"
    }
    assert_reply ref, :ok, reply

    assert reply == %{
      data: %{"users" => [%{"name" => "Bob"}]}
    }
  end

  test "basic query works with errors", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "{users { errorField }}"
    }
    assert_reply ref, :ok, reply

    expected = %{errors: [%{locations: [%{column: 0, line: 1}], message: "Cannot query field \"errorField\" on type \"User\"."}]}

    assert expected == reply
  end

  test "subscription with errors returns errors", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "subscription {commentAdded { errorField }}"
    }
    assert_reply ref, :ok, reply

    expected = %{errors: [%{locations: [%{column: 0, line: 1}], message: "Cannot query field \"errorField\" on type \"Comment\"."}]}

    assert expected == reply
  end

  test "subscription can work", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "subscription {commentAdded { contents }}"
    }
    assert_reply ref, :ok, %{ref: subscription_ref}

    ref = push socket, "doc", %{
      "query" => "mutation {addComment(contents: \"hello world\") { contents }}"
    }
    assert_reply ref, :ok, reply

    expected = %{data: %{"addComment" => %{"contents" => "hello world"}}}
    assert expected == reply

    assert_push "subscription:data", push
    expected = %{result: %{data: %{"commentAdded" => %{"contents" => "hello world"}}}, subscription_id: subscription_ref}
    assert expected == push
  end
end
