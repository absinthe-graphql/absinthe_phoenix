defmodule Absinthe.Phoenix.SubscriptionTest do
  @moduledoc """
  Convenience functions for subscription tests
  """

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

  def push_doc(socket, doc, opts \\ []) do
    Phoenix.ChannelTest.push(socket, "doc", %{
      "query" => doc,
      "variables" => opts[:variables]
    })
  end
end
