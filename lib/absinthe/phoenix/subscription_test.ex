defmodule Absinthe.Phoenix.SubscriptionTest do
  @moduledoc """
  Convenience functions for subscription tests
  """

  @typep opts ::
           [variables: Access.container()]
           | %{variables: Access.container()}

  defmacro __using__(schema: schema) do
    quote do
      setup_all do
        Absinthe.Test.prime(unquote(schema))
      end

      import unquote(__MODULE__)
    end
  end

  def join_absinthe(socket) do
    with {:ok, _, socket} <-
           Phoenix.ChannelTest.subscribe_and_join(socket, "__absinthe__:control", %{}) do
      {:ok, socket}
    end
  end

  @doc """
  A small wrapper around `Phoenix.ChannelTest.push/3`.

  The only option that is used is `opts[:variables]` - all other options are
  ignored.
  """
  @spec push_doc(Phoenix.Socket.t(), String.t(), opts) :: reference()
  def push_doc(socket, query, opts \\ []) do
    Phoenix.ChannelTest.push(socket, "doc", %{
      "query" => query,
      "variables" => opts[:variables] || %{}
    })
  end
end
