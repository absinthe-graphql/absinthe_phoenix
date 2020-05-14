defmodule Absinthe.Phoenix.Channel do
  use Phoenix.Channel
  require Logger

  @moduledoc false

  @doc false
  def __using__(_) do
    raise """
    ----------------------------------------------
    You should `use Absinthe.Phoenix.Socket`
    ----------------------------------------------
    """
  end

  @doc false
  def join("__absinthe__:control", _, socket) do
    schema = socket.assigns[:__absinthe_schema__]
    pipeline = socket.assigns[:__absinthe_pipeline__]

    absinthe_config = Map.get(socket.assigns, :absinthe, %{})

    opts =
      absinthe_config
      |> Map.get(:opts, [])
      |> Keyword.update(:context, %{pubsub: socket.endpoint}, fn context ->
        Map.put_new(context, :pubsub, socket.endpoint)
      end)

    absinthe_config =
      put_in(absinthe_config[:opts], opts)
      |> Map.update(:schema, schema, & &1)

    absinthe_config =
      Map.put(absinthe_config, :pipeline, pipeline || {__MODULE__, :default_pipeline})

    socket = socket |> assign(:absinthe, absinthe_config)
    {:ok, socket}
  end

  @doc false
  def handle_in("doc", payload, socket) do
    config = socket.assigns[:absinthe]

    with variables when is_map(variables) <- Map.get(payload, "variables", %{}) do
      opts = Keyword.put(config.opts, :variables, variables)

      query = Map.get(payload, "query", "")

      Absinthe.Logger.log_run(:debug, {
        query,
        config.schema,
        [],
        opts
      })

      {reply, socket} = run_doc(socket, query, config, opts)

      Logger.debug(fn ->
        """
        -- Absinthe Phoenix Reply --
        #{inspect(reply)}
        ----------------------------
        """
      end)

      if reply != :noreply do
        {:reply, reply, socket}
      else
        {:noreply, socket}
      end
    else
      _ -> {:reply, {:error, %{error: "Could not parse variables as map"}}, socket}
    end
  end

  def handle_in("unsubscribe", %{"subscriptionId" => doc_id}, socket) do
    pubsub =
      socket.assigns
      |> Map.get(:absinthe, %{})
      |> Map.get(:opts, [])
      |> Keyword.get(:context, %{})
      |> Map.get(:pubsub, socket.endpoint)

    Phoenix.PubSub.unsubscribe(socket.pubsub_server, doc_id)
    Absinthe.Subscription.unsubscribe(pubsub, doc_id)
    {:reply, {:ok, %{subscriptionId: doc_id}}, socket}
  end

  defp run_doc(socket, query, config, opts) do
    case run(query, config[:schema], config[:pipeline], opts) do
      {:ok, %{"subscribed" => topic}, context} ->
        %{transport_pid: transport_pid, serializer: serializer, pubsub_server: pubsub_server} =
          socket

        :ok =
          Phoenix.PubSub.subscribe(
            pubsub_server,
            topic,
            metadata: {:fastlane, transport_pid, serializer, []},
            link: true
          )

        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)
        {{:ok, %{subscriptionId: topic}}, socket}

      {:ok, %{data: _} = reply, context} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)
        {{:ok, reply}, socket}

      {:ok, %{errors: _} = reply, context} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)
        {{:error, reply}, socket}

      {:error, reply} ->
        {reply, socket}
    end
  end

  defp run(document, schema, pipeline, options) do
    {module, fun} = pipeline

    case Absinthe.Pipeline.run(document, apply(module, fun, [schema, options])) do
      {:ok, %{result: result, execution: res}, _phases} ->
        {:ok, result, res.context}

      {:error, msg, _phases} ->
        {:error, msg}
    end
  end

  @doc false
  def default_pipeline(schema, options) do
    schema
    |> Absinthe.Pipeline.for_document(options)
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
