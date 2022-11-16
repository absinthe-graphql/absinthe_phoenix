defmodule Absinthe.Phoenix.SubscriptionTest do
  @moduledoc """
  Convenience functions for subscription tests.

  ## Example

      defmodule MyApp.SocketTest do
        use ExUnit.Case
        import Absinthe.Phoenix.SubscriptionTest

        test "once unread thread is created, unread threads count changes subscription gets an update" do
          socket = build_socket(MyApp.Endpoint, MyApp.Socket)

          subscription_id =
            start_subscription(socket, \"""
              subscription {
                unreadThreadsCountChanges {
                  count
                }
              }
            \""")

          create_unread_thread()

          assert_subscription_update(subscription_id, %{
            "unreadThreadsCountChanges" => %{"count" => 1}
          })

          refute_subscription_update(subscription_id)
        end
      end
  """

  @typep push_doc_opts ::
           [variables: Access.container()]
           | %{variables: Access.container()}

  @doc false
  defmacro __using__(schema: schema) do
    IO.warn """
    Using Absinthe.Phoenix.SubscriptionTest is deprecated, instead of:

        use Absinthe.Phoenix.SubscriptionTest, schema: MyApp.Schema

    do:

        import Absinthe.Phoenix.SubscriptionTest

        setup_all do
          Absinthe.Test.prime(MyApp.Schema)
        end
    """, Macro.Env.stacktrace(__CALLER__)

    quote do
      setup_all do
        Absinthe.Test.prime(unquote(schema))
      end

      import unquote(__MODULE__)
    end
  end

  @doc ~S"""
  Build a socket connection to a `Absinthe.Phoenix.Socket` using the given `Absinthe.Phoenix.Endpoint`.

  Optionally pass `socket_params` which will will be passed to the `Absinthe.Phoenix.Socket.connect` function.

  ## Example

      AL.MobileApi.AbsinthePhoenixSocketTest.build_socket(
        MyApp.Endpoint,
        MyApp.Socket,
        %{
          "Authorization" => "Bearer #{auth_token}"
        }
      )
  """
  @spec build_socket(term(), term(), map()) :: reference()
  def build_socket(endpoint, socket_module, socket_params \\ %{}) do
    {:ok, socket} = Phoenix.ChannelTest.__connect__(endpoint, socket_module, socket_params, %{})
    {:ok, socket} = join_absinthe(socket)
    socket
  end

  @doc """
  Start a GraphQL subscription using the given `socket` connection (built using `build_socket`).

  Returns `subscription_id`.

  ## Example

      subscription_id =
        start_subscription(socket, \"""
          subscription {
            unreadThreadsCountChanges {
              count
            }
          }
        \""")
  """
  @spec start_subscription(reference(), String.t(), keyword()) :: String.t()
  defmacro start_subscription(
             socket,
             query,
             opts \\ []
           ) do
    quote do
      opts = unquote(opts)
      variables = Keyword.get(opts, :variables, %{})
      timeout = Keyword.get(opts, :timeout, Application.fetch_env!(:ex_unit, :assert_receive_timeout))

      ref = Absinthe.Phoenix.SubscriptionTest.push_doc(unquote(socket), unquote(query), variables)

      Phoenix.ChannelTest.assert_reply(
        ref,
        :ok,
        %{subscriptionId: subscription_id},
        timeout
      )

      subscription_id
    end
  end

  @doc """
  Assert that the GraphQL subscription has received data update.

  ## Example

      assert_subscription_update(subscription_id, %{
        "unreadThreadsCountChanges" => %{"count" => 1}
      })
  """
  @spec assert_subscription_update(String.t(), map(), integer()) :: nil
  defmacro assert_subscription_update(
             subscription_id,
             data,
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout)
           ) do
    quote do
      Phoenix.ChannelTest.assert_push(
        "subscription:data",
        %{
          subscriptionId: ^unquote(subscription_id),
          result: %{
            data: unquote(data)
          }
        },
        unquote(timeout)
      )
    end
  end

  @doc """
  Assert that the GraphQL subscription has received no data updates.

  ## Example

      refute_subscription_update(subscription_id)
  """
  @spec refute_subscription_update(String.t(), integer()) :: nil
  defmacro refute_subscription_update(
             subscription_id,
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout)
           ) do
    quote do
      Phoenix.ChannelTest.refute_push(
        "subscription:data",
        %{
          subscriptionId: ^unquote(subscription_id)
        },
        unquote(timeout)
      )
    end
  end

  @doc false
  def join_absinthe(socket) do
    with {:ok, _, socket} <-
           Phoenix.ChannelTest.subscribe_and_join(socket, "__absinthe__:control", %{}) do
      {:ok, socket}
    end
  end

  @doc false
  @spec push_doc(Phoenix.Socket.t(), String.t(), push_doc_opts) :: reference()
  def push_doc(socket, query, opts \\ []) do
    Phoenix.ChannelTest.push(socket, "doc", %{
      "query" => query,
      "variables" => opts[:variables] || %{}
    })
  end
end
