defmodule Absinthe.Phoenix do
  defmacro __using__(_) do
    quote do
      use Absinthe.Schema

      plug Absinthe.Phoenix
    end
  end

  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, controller} <- Map.fetch(conn.private, :phoenix_controller),
         {:ok, input_type_name} <- Map.fetch(conn.private, :phoenix_action),
         {:ok, input_type} <- fetch_input_type(controller, input_type_name) do
      validate(conn.params, controller, input_type)
    end
    |> case do
      {:ok, params} -> %{conn | params: params}
      {:error, _} ->
        conn
        |> send_resp(400, "")
    end
  end

  defp validate(params, schema, input_type) do
    input_type.name
    |> build_variable_definition
    |> Absinthe.Execution.Variables.build_definition({:ok, execution(schema, params)})
    |> case do
      {:ok, exec} ->
        {:ok, exec.variables.processed["input"].value}

      {:error, exec} ->
        {:error, rename exec.errors}
    end
  end

  defp rename(errors) do
    Enum.map(errors, fn
      %{message: msg} = error ->
        %{error | message: String.replace(msg, "Variable", "Parameter")}
    end)
  end

  defp execution(schema, params) do
    %Absinthe.Execution{
      schema: schema,
      adapter: Absinthe.Adapter.Passthrough,
      variables: %Absinthe.Execution.Variables{raw: %{"input" => params}}
    }
  end

  defp fetch_input_type(schema, name) do
    case Absinthe.Schema.lookup_type(schema, name) do
      nil -> :error
      type -> {:ok, type}
    end
  end

  defp build_variable_definition(input_type_name) do
    %Absinthe.Language.VariableDefinition{
      variable: %Absinthe.Language.Variable{
        name: "input"
      },
      type: %Absinthe.Language.NamedType{name: input_type_name},
    }
  end
end
