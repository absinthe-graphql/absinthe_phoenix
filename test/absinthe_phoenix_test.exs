defmodule Absinthe.PhoenixTest do
  use ExUnit.Case, async: true
  use Absinthe.Phoenix.ChannelCase

  setup_all do
    Absinthe.Test.prime(Schema)

    {:ok, _} = Absinthe.Phoenix.TestEndpoint.start_link
    {:ok, _} = Absinthe.Subscription.start_link(Absinthe.Phoenix.TestEndpoint)
    :ok
  end

  setup do
    {:ok, _, socket} =
      socket("asdf", absinthe: %{schema: Schema, opts: []})
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

  test "can provide execution context (ie for authorization)", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "{viewer { name }}",
      "context" => %{"authorization" => "jwt_token"}
    }

    assert_reply ref, :ok, reply
    assert reply == %{
      data: %{"viewer" => %{"name" => "Jane"}}
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
    assert_reply ref, :ok, %{subscriptionId: subscription_ref}

    ref = push socket, "doc", %{
      "query" => "mutation {addComment(contents: \"hello world\") { contents }}"
    }
    assert_reply ref, :ok, reply

    expected = %{data: %{"addComment" => %{"contents" => "hello world"}}}
    assert expected == reply

    assert_push "subscription:data", push
    expected = %{result: %{data: %{"commentAdded" => %{"contents" => "hello world"}}}, subscriptionId: subscription_ref}
    assert expected == push
  end

  test "subscriptions that raise errors do not cause problems for mutations", %{socket: socket} do
    ref = push socket, "doc", %{
      "query" => "subscription {raises { contents }}"
    }
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref}

    ref = push socket, "doc", %{
      "query" => "mutation {addComment(contents: \"raise\") { contents }}"
    }
    assert_reply ref, :ok, reply
    expected = %{data: %{"addComment" => %{"contents" => "raise"}}}
    assert expected == reply
  end
end
