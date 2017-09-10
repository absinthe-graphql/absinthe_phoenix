defmodule Absinthe.Phoenix.Controller.Action do
  import Plug.Conn

  @behaviour Plug

  @type opts :: [
    {:schema, Absinthe.Schema.t},
    {:document_provider, Absinthe.Plug.DocumentProvider.Compiled.t},
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
    case graphql_document(conn, Keyword.fetch!(opts, :document_provider)) do
      nil ->
        conn
      document ->
        execute(conn, schema, document)
    end
  end

  @spec execute(conn :: Plug.Conn.t, schema :: Absinthe.Schema.t, document :: Absinthe.Blueprint.t) :: Plug.Conn.t
  defp execute(conn, schema, document) do
    case Absinthe.Pipeline.run(document, pipeline(schema, conn.params)) do
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

end
