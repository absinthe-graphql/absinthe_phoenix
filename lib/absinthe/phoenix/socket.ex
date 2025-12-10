defmodule Absinthe.Phoenix.Socket do
  @moduledoc ~S"""
  `Absinthe.Phoenix.Socket` is used as a module for setting up a control
  channel for handling GraphQL subscriptions.

  ## Examples

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

  If you're on Phoenix 1.2 see `put_schema/2`.

  ## Garbage Collection

  In some workloads, the Channel Process responsible for handling [subscriptions may accumulate
  some gargage](https://elixirforum.com/t/why-does-garbage-collection-not-work-as-intended/50613/2), that is not being collected by the Erlang VM. A workaround for this is to instruct
  the process to periodically tell the VM to collect its garbage. This can be done by setting the
  `gc_interval`.

        use Absinthe.Phoenix.Socket,
          schema: MyApp.Web.Schema,
          gc_interval: 10_000

  """

  defmacro __using__(opts) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    schema = Keyword.get(opts, :schema)
    pipeline = Keyword.get(opts, :pipeline)
    presence_config = Keyword.get(opts, :presence_config)
    gc_interval = Keyword.get(opts, :gc_interval)

    quote do
      channel(
        "__absinthe__:*",
        Absinthe.Phoenix.Channel,
        assigns: %{
          __absinthe_schema__: unquote(schema),
          __absinthe_pipeline__: unquote(pipeline),
          __absinthe_presence_config__: unquote(presence_config),
          __absinthe_gc_interval__: unquote(gc_interval)
        }
      )
    end
  end

  @doc """
  Configure Absinthe options for a socket.

  ## Examples

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
  Configure the schema for a socket.

  Only use this if you are not yet on Phoenix 1.3. If you're on Phoenix 1.3,
  read the moduledocs.
  """
  @spec put_schema(Phoenix.Socket.t(), Absinthe.Schema.t()) :: Phoenix.Socket.t()
  def put_schema(socket, schema) do
    absinthe_assigns =
      socket.assigns
      |> Map.get(:absinthe, %{})
      |> Map.put(:schema, schema)

    Phoenix.Socket.assign(socket, :absinthe, absinthe_assigns)
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:__using__, 1}})

  defp expand_alias(other, _env), do: other
end
