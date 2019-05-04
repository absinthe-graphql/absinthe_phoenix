defmodule Absinthe.Phoenix.Socket do
  @moduledoc ~S"""
  `Absinthe.Phoenix.Socket` is used as a module for setting up a control
  channel for handling GraphQL subscriptions.

  ## Example

      defmodule MyApp.Web.UserSocket do
        use Phoenix.Socket
        use Absinthe.Phoenix.Socket,
          schema: MyApp.Web.Schema

        transport :websocket, Phoenix.Transports.WebSocket

        def connect(params, socket) do
          socket = Absinthe.Phoenix.Socket.put_options(socket, [
            context: %{current_user: find_current_user(params)}
          ])
          {:ok, socket}
        end

        def id(_socket), do: nil
      end

  ## Phoenix 1.2

  If you're on Phoenix 1.2 see `put_schema/2`
  """

  defmacro __using__(opts) do
    schema = Keyword.get(opts, :schema)
    pipeline = Keyword.get(opts, :pipeline)

    quote do
      channel(
        "__absinthe__:*",
        Absinthe.Phoenix.Channel,
        assigns: %{
          __absinthe_schema__: unquote(schema),
          __absinthe_pipeline__: unquote(pipeline)
        }
      )
    end
  end

  @doc """
  Configure Absinthe options for a socket

  ## Examples

  ```
  def connect(params, socket) do
    current_user = current_user(params)
    socket = Absinthe.Phoenix.Socket.put_options(socket, context: %{
      current_user: current_user
    })
    {:ok, socket}
  end

  defp current_user(%{"user_id" => id}) do
    MyApp.Repo.get(User, id)
  end
  ```
  """
  @spec put_options(Phoenix.Socket.t(), Absinthe.run_opts()) :: Phoenix.Socket.t()
  def put_options(socket, opts) do
    absinthe_assigns =
      socket.assigns
      |> Map.get(:absinthe, %{})
      |> Map.put(:opts, opts)

    Phoenix.Socket.assign(socket, :absinthe, absinthe_assigns)
  end

  @doc false
  @deprecated "Use put_options/2 instead."
  def put_opts(socket, opts) do
    put_options(socket, opts)
  end

  @doc """
  Configure the schema for a socket

  Only use this if you are not yet on Phoenix 1.3. If you're on Phoenix 1.3, read the moduledocs.


  """
  @spec put_schema(Phoenix.Socket.t(), Absinthe.Schema.t()) :: Phoenix.Socket.t()
  def put_schema(socket, schema) do
    absinthe_assigns =
      socket.assigns
      |> Map.get(:absinthe, %{})
      |> Map.put(:schema, schema)

    Phoenix.Socket.assign(socket, :absinthe, absinthe_assigns)
  end
end
