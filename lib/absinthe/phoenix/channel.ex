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

    with variables when is_map(variables) <- extract_variables(payload) do
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

  def handle_info(
        %Phoenix.Socket.Broadcast{payload: %{result: %{ordinal: ordinal}}} = msg,
        socket
      )
      when not is_nil(ordinal) do
    absinthe_assigns = Map.get(socket.assigns, :absinthe, %{})
    last_ordinal = absinthe_assigns[:subscription_ordinals][msg.topic]

    cond do
      last_ordinal == nil or last_ordinal < ordinal ->
        send_msg(msg, socket)
        socket = update_ordinal(socket, msg.topic, ordinal)
        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info(msg, socket) do
    send_msg(msg, socket)
    {:noreply, socket}
  end

  defp send_msg(msg, socket) do
    {_ordinal, msg} = pop_in(msg.payload.result[:ordinal])
    encoded_msg = socket.serializer.fastlane!(msg)
    send(socket.transport_pid, encoded_msg)
  end

  defp update_ordinal(socket, topic, ordinal) do
    absinthe_assigns = Map.get(socket.assigns, :absinthe, %{})

    ordinals =
      absinthe_assigns
      |> Map.get(:subscription_ordinals, %{})
      |> Map.put(topic, ordinal)

    Phoenix.Socket.assign(
      socket,
      :absinthe,
      Map.put(absinthe_assigns, :subscription_ordinals, ordinals)
    )
  end

  defp run_doc(socket, query, config, opts) do
    case run(query, config[:schema], config[:pipeline], opts) do
      {:ok, %{"subscribed" => topic}, context} ->
        pubsub_subscribe(topic, socket)
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)

        {{:ok, %{subscriptionId: topic}}, socket}

      {:more, %{"subscribed" => topic}, continuation, context} ->
        reply(socket_ref(socket), {:ok, %{subscriptionId: topic}})

        pubsub_subscribe(topic, socket)
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)

        handle_subscription_continuation(continuation, topic, socket)

        {:noreply, socket}

      {:ok, %{data: _} = reply, context} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)
        {{:ok, reply}, socket}

      {:ok, %{errors: _} = reply, context} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)
        {{:error, reply}, socket}

      {:more, %{data: _} = reply, continuation, context} ->
        id = new_query_id()

        socket =
          socket
          |> Absinthe.Phoenix.Socket.put_options(context: context)
          |> handle_continuation(continuation, id)

        {{:ok, add_query_id(reply, id)}, socket}

      {:error, reply} ->
        {reply, socket}
    end
  end

  defp run(document, schema, pipeline, options) do
    {module, fun} = pipeline

    case Absinthe.Pipeline.run(document, apply(module, fun, [schema, options])) do
      {:ok, %{result: %{continuation: continuation} = result, execution: res}, _phases} ->
        {:more, Map.delete(result, :continuation), continuation, res.context}

      {:ok, %{result: result, execution: res}, _phases} ->
        {:ok, result, res.context}

      {:error, msg, _phases} ->
        {:error, msg}
    end
  end

  defp pubsub_subscribe(
         topic,
         %{transport_pid: transport_pid, serializer: serializer, pubsub_server: pubsub_server}
       ) do
    :ok =
      Phoenix.PubSub.subscribe(
        pubsub_server,
        topic,
        metadata: {:fastlane, transport_pid, serializer, ["subscription:data"]},
        link: true
      )
  end

  defp extract_variables(payload) do
    case Map.get(payload, "variables", %{}) do
      nil -> %{}
      map -> map
    end
  end

  @doc false
  def default_pipeline(schema, options) do
    schema
    |> Absinthe.Pipeline.for_document(options)
  end

  defp handle_continuation(socket, continuation, id) do
    case Absinthe.Pipeline.continue(continuation) do
      {:ok, %{result: %{continuation: next_continuation} = result}, _phases} ->
        result =
          result
          |> Map.delete(:continuation)
          |> add_query_id(id)

        push(socket, "doc", result)
        handle_continuation(socket, next_continuation, id)

      {:ok, %{result: result}, _phases} ->
        push(socket, "doc", add_query_id(result, id))

      {:ok, %{errors: errors}, _phases} ->
        push(socket, "doc", add_query_id(%{errors: errors}, id))

      {:error, msg, _phases} ->
        push(socket, "doc", add_query_id(msg, id))

      {:ok, %{result: :no_more_results}, _phases} ->
        socket
    end
  end

  defp new_query_id,
    do: "absinthe_query:" <> to_string(:erlang.unique_integer([:positive]))

  defp add_query_id(result, id), do: Map.put(result, :queryId, id)

  defp handle_subscription_continuation(continuation, topic, socket) do
    case Absinthe.Pipeline.continue(continuation) do
      {:ok, %{result: :no_more_results}, _phases} ->
        :ok

      {:ok, %{result: result}, _phases} ->
        socket = push_subscription_item(result.data, topic, socket)

        case result[:continuation] do
          nil -> :ok
          c -> handle_subscription_continuation(c, topic, socket)
        end
    end
  end

  defp push_subscription_item(data, topic, socket) do
    msg = %Phoenix.Socket.Broadcast{
      topic: topic,
      event: "subscription:data",
      payload: %{result: %{data: data}, subscriptionId: topic}
    }

    {:noreply, socket} = handle_info(msg, socket)

    socket
  end
end
