defmodule Absinthe.Phoenix.Controller.Action do
  import Plug.Conn

  @behaviour Plug

  @type opts :: [
    {:schema, Absinthe.Schema.t},
  ]

  @impl true
  @spec init(opts :: opts) :: opts
  def init(opts \\ []) do
    opts
  end

  @impl true
  @spec call(conn :: Plug.Conn.t, opts :: opts) :: Plug.Conn.t
  def call(conn, opts) do
    schema = Keyword.fetch!(opts, :schema)
    controller = conn.private.phoenix_controller
    document_provider = Module.safe_concat(controller, GraphQL)
    case graphql_document(conn, document_provider) do
      nil ->
        conn
      document ->
        execute(conn, schema, controller, document)
    end
  end

  @spec execute(conn :: Plug.Conn.t, schema :: Absinthe.Schema.t, controller :: module, document :: Absinthe.Blueprint.t) :: Plug.Conn.t
  defp execute(conn, schema, controller, document) do
    variables = parse_variables(document, conn.params, schema, controller)
    case Absinthe.Pipeline.run(document, pipeline(schema, variables)) do
      {:ok, %{result: result}, _phases} ->
        conn
        |> Plug.Conn.put_private(:absinthe_variables, conn.params)
        |> Map.put(:params, result)
      {:error, msg, _phases} ->
        conn
        |> send_resp(500, msg)
    end
  end

  @spec document_key(conn :: Plug.Conn.t) :: nil | atom
  defp document_key(%{private: %{phoenix_action: name}}), do: to_string(name)
  defp document_key(_), do: nil

  @spec graphql_document(conn :: Plug.Conn.t, document_provider :: Absinthe.Plug.DocumentProvider.Compiled.t) :: nil | Absinthe.Blueprint.t
  defp graphql_document(conn, document_provider) do
    case document_key(conn) do
      nil ->
        nil
      key ->
        Absinthe.Plug.DocumentProvider.Compiled.get(document_provider,
          key, :compiled
        )
    end
  end

  @spec pipeline(schema :: Absinthe.Schema.t, variables :: %{String.t => any}) :: Absinthe.Pipeline.t
  defp pipeline(schema, variables) do
    pipeline_remainder(schema, variables) ++ [Absinthe.Phoenix.Controller.Result]
  end

  @spec pipeline_remainder(schema :: Absinthe.Schema.t, variables :: %{String.t => any}) :: Absinthe.Pipeline.t
  defp pipeline_remainder(schema, variables) do
    Absinthe.Pipeline.for_document(schema,
      variables: variables,
      result_phase: Absinthe.Phoenix.Controller.Result
    )
    |> Absinthe.Pipeline.from(Absinthe.Phase.Document.Variables)
    |> Absinthe.Pipeline.before(Absinthe.Phase.Document.Result)
    |> Absinthe.Pipeline.without(Absinthe.Phase.Document.Validation.ScalarLeafs)
  end

  @spec parse_variables(document :: Absinthe.Blueprint.t, params :: map, schema :: Absinthe.Schema.t, controller :: module) :: %{String.t => any}
  defp parse_variables(document, params, schema, controller) do
    params
    |> do_parse_variables(variable_types(document, schema), controller)
  end

  @spec do_parse_variables(params :: map, variable_types :: %{String.t => Absinthe.Type.t}, controller :: module) :: map
  defp do_parse_variables(params, variable_types, controller) do
    for {name, raw_value} <- params, into: %{} do
      target_type = Map.fetch!(variable_types, name)
      {
        name,
        controller.coerce_to_graphql_input(raw_value, target_type)
      }
    end
  end

  @type_mapping %{
    Absinthe.Blueprint.TypeReference.List => Absinthe.Type.List,
    Absinthe.Blueprint.TypeReference.NonNull => Absinthe.Type.NonNull
  }

  # TODO: Extract this from here & Absinthe.Phase.Schema to a common function
  @spec type_reference_to_type(Absinthe.Blueprint.TypeReference.t, Absinthe.Schema.t) :: Absinthe.Type.t
  defp type_reference_to_type(%Absinthe.Blueprint.TypeReference.Name{name: name}, schema) do
    Absinthe.Schema.lookup_type(schema, name)
  end
  for {blueprint_type, core_type} <- @type_mapping do
    defp type_reference_to_type(%unquote(blueprint_type){} = node, schema) do
      inner = type_reference_to_type(node.of_type, schema)
      %unquote(core_type){of_type: inner}
    end
  end

  # TODO: Extract this to a function (probably on Absinthe.Blueprint.Document.Operation)
  @spec variable_types(Absinthe.Blueprint.t, Absinthe.Schema.t) :: %{String.t => Absinthe.Type.t}
  defp variable_types(document, schema) do
    for %{name: name, type: type} <- Absinthe.Blueprint.current_operation(document).variable_definitions, into: %{} do
      {name, type_reference_to_type(type, schema)}
    end
  end

end
