defmodule Absinthe.PhoenixTest do
  use ExUnit.Case
  use Absinthe.Phoenix.ChannelCase

  import ExUnit.CaptureLog

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

  setup do
    {:ok, _, socket} =
      socket(Absinthe.Phoenix.TestSocket, nil, absinthe: %{schema: Schema, opts: []})
      |> subscribe_and_join(Absinthe.Phoenix.Channel, "__absinthe__:control")

    {:ok, socket: socket}
  end

  test "basic query works", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "{users { name }}"
      })

    assert_reply(ref, :ok, reply)

    assert reply == %{
             data: %{"users" => [%{"name" => "Bob"}]}
           }
  end

  test "basic query works with errors", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "{users { errorField }}"
      })

    assert_reply(ref, :error, reply)

    expected = %{
      errors: [
        %{
          locations: [%{column: 10, line: 1}],
          message: "Cannot query field \"errorField\" on type \"User\"."
        }
      ]
    }

    assert expected == reply
  end

  test "subscription with errors returns errors", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {commentAdded { errorField }}"
      })

    assert_reply(ref, :error, reply)

    expected = %{
      errors: [
        %{
          locations: [%{column: 30, line: 1}],
          message: "Cannot query field \"errorField\" on type \"Comment\"."
        }
      ]
    }

    assert expected == reply
  end

  test "subscription can work", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {commentAdded { contents }}"
      })

    assert_reply(ref, :ok, %{subscriptionId: subscription_ref})

    ref =
      push(socket, "doc", %{
        "query" => "mutation ($contents: String!) {addComment(contents: $contents) { contents }}",
        "variables" => %{"contents" => "hello world"}
      })

    assert_reply(ref, :ok, reply)

    expected = %{data: %{"addComment" => %{"contents" => "hello world"}}}
    assert expected == reply

    assert_push("subscription:data", push)

    expected = %{
      result: %{data: %{"commentAdded" => %{"contents" => "hello world"}}},
      subscriptionId: subscription_ref
    }

    assert expected == push
  end

  test "subscriptions that raise errors do not cause problems for mutations", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {raises { contents }}"
      })

    assert_reply(ref, :ok, %{subscriptionId: _subscription_ref})

    log =
      capture_log(fn ->
        ref =
          push(socket, "doc", %{
            "query" => "mutation {addComment(contents: \"raise\") { contents }}"
          })

        assert_reply(ref, :ok, reply)
        expected = %{data: %{"addComment" => %{"contents" => "raise"}}}
        assert expected == reply
      end)

    assert String.contains?(log, "boom")
  end

  test "context changes are persisted across documents", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "{me { name }}"
      })

    assert_reply(ref, :ok, reply)

    assert reply == %{
             data: %{"me" => nil}
           }

    ref =
      push(socket, "doc", %{
        "query" => "mutation {login { name }}"
      })

    assert_reply(ref, :ok, reply)

    assert reply == %{
             data: %{"login" => %{"name" => "Ben"}}
           }

    ref =
      push(socket, "doc", %{
        "query" => "{me { name }}"
      })

    assert_reply(ref, :ok, reply)

    assert reply == %{
             data: %{"me" => %{"name" => "Ben"}}
           }
  end

  test "config functions can return errors", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {errors { __typename }}"
      })

    assert_reply(ref, :error, reply)

    assert reply == %{errors: [%{locations: [%{column: 15, line: 1}], message: "unauthorized"}]}
  end

  test "can't do multiple fields on a subscription root", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {errors { __typename }, foo: errors { __typename }}"
      })

    assert_reply(ref, :error, reply)

    assert reply == %{
             errors: [
               %{
                 locations: [%{column: 1, line: 1}],
                 message: "Only one field is permitted on the root object when subscribing"
               }
             ]
           }
  end

  test "valid variables succeed", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "mutation ($val: Int) {mutate (val: $val)}",
        "variables" => %{val: 5}
      })

    assert_reply(ref, :ok, reply)

    assert reply == %{
             data: %{"mutate" => 5}
           }
  end

  test "inavlid variables returns error", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "mutation ($val: Int) {mutate (val: $val)}",
        "variables" => [val: 5]
      })

    assert_reply(ref, :error, reply)

    assert reply == %{
             error: "Could not parse variables as map"
           }
  end

  test "empty variables succeed", %{socket: socket} do
    ref =
      push(socket, "doc", %{
        "query" => "subscription {commentAdded { contents }}",
        "variables" => nil
      })

    assert_reply(ref, :ok, %{subscriptionId: _subscription_ref})
  end
end
