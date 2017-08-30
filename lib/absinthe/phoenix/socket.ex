defmodule Absinthe.Phoenix.Socket do
  @moduledoc ~S"""
  `Absinthe.Phoenix.Socket` is used as a module for setting up a control
  channel for handling GraphQL subscriptions.

  ## Example

      defmodule MyApp.Web.UserSocket do
        use Phoenix.Socket
        use Absinthe.Phoenix.Socket

        transport :websocket, Phoenix.Transports.WebSocket

        def connect(params, socket) do
          absinthe_config = %{
            schema: MyApp.Web.Schema,
            context: %{current_user: find_current_user(params)}
          }
          {:ok, assign(socket, :absinthe, absinthe_config)}
        end

        def id(_socket), do: nil
      end
    """

  defmacro __using__(_) do
    quote do
      channel "__absinthe__:*", Absinthe.Phoenix.Channel
    end
  end
end
