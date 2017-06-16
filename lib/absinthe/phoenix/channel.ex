defmodule Absinthe.Phoenix.Channel do
  use Phoenix.Channel
  require Logger

  defmacro __using__(_) do
    quote do
      channel "__absinthe__:*", unquote(__MODULE__)
    end
  end

  @doc false
  def join("__absinthe__:control", _, socket) do
    defaults_opts = [
      jump_phases: false
    ]

    absinthe_config =
      socket.assigns[:absinthe]
      |> Map.new
      |> Map.update(:opts, defaults_opts, fn opts ->
        Keyword.merge(opts, defaults_opts)
      end)

    socket = socket |> assign(:absinthe, absinthe_config)
    {:ok, socket}
  end

  @doc false
  def handle_in("doc", %{"query" => query, "variables" => variables}, socket) do
    config = socket.assigns[:absinthe]
    config = put_in(config.opts[:variables], variables)

    Absinthe.Logger.log_run(:debug, {
      query,
      config.schema,
      [],
      config.opts,
    })

    handle_doc(query, config, socket)
  end

  @doc false
  def handle_info(%{event: "subscription:data", payload: payload}, socket) do
    %{subscription_id: id, result: result} = payload
    push(socket, event, %{"subscriptionId" => id, "result" => result})
    {:noreply, socket}
  end

  @doc false
  def handle_doc(query, config, socket) do
    query
    |> prepare(config)
    |> case do
      {:ok, doc} ->
        doc
        |> classify
        |> execute(doc, query, config, socket)
    end
  end

  defp classify(doc) do
    Absinthe.Blueprint.current_operation(doc).schema_node.identifier
  end

  defp execute(:subscription, doc, query, config, socket) do
    hash = :erlang.phash2({query, config})
    topic = "__absinthe__:#{hash}"

    socket.endpoint.subscribe(topic)

    # # TODO: Use fast lane
    # :ok = Phoenix.PubSub.subscribe(socket.pubsub_server, topic, [
    #   fastlane: {socket.transport_pid, socket.serializer, []},
    #   link: true,
    # ])

    pid = self()
    for field_key <- field_keys(doc) do
      Absinthe.Subscriptions.Manager.subscribe(socket.endpoint, field_key, topic, doc, pid)
    end

    {:reply, {:ok, %{subscriptionId: topic}}, socket}
  end
  defp execute(_, doc, _query, config, socket) do
    {:ok, %{result: result}, _} = Absinthe.Pipeline.run(doc, finalization_pipeline(config))
    {:reply, {:ok, result}, socket}
  end

  defp field_keys(doc) do
    doc
    |> Absinthe.Blueprint.current_operation
    |> Map.fetch!(:selections)
    |> Enum.map(fn %{schema_node: schema_node, argument_data: argument_data} ->
      name = schema_node.__reference__.identifier

      key = case schema_node.topic do
        fun when is_function(fun, 1) ->
          schema_node.topic.(argument_data)
        nil ->
          to_string(name)
      end

      {name, key}
    end)
  end

  def prepare(query, config) do
    case Absinthe.Pipeline.run(query, preparation_pipeline(config)) do
      {:ok, blueprint, _} ->
        {:ok, blueprint}
    end
  end

  @doc false
  def preparation_pipeline(config) do
    config.schema
    |> Absinthe.Pipeline.for_document(config.opts)
    |> Absinthe.Pipeline.before(Absinthe.Phase.Document.Execution.Resolution)
  end

  @doc false
  def finalization_pipeline(config) do
    config.schema
    |> Absinthe.Pipeline.for_document(config.opts)
    |> Absinthe.Pipeline.from(Absinthe.Phase.Document.Execution.Resolution)
  end
end
