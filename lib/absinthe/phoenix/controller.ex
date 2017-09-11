defmodule Absinthe.Phoenix.Controller do

  defmacro __using__(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)
    quote do
      @behaviour unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @on_definition {unquote(__MODULE__), :register_graphql_action}
      Module.register_attribute(__MODULE__, :graphql_actions, accumulate: true)

      @absinthe_schema unquote(schema)

      plug unquote(__MODULE__).Action

      @impl unquote(__MODULE__)
      @spec cast_param(value :: any, target_type :: Absinthe.Type.t, schema :: Absinthe.Schema.t) :: any
      def cast_param(value, %Absinthe.Type.NonNull{of_type: inner_target_type}, schema) do
        cast_param(value, inner_target_type, schema)
      end
      def cast_param(values, %Absinthe.Type.List{of_type: inner_target_type}, schema) when is_list(values) do
        for value <- values do
          cast_param(value, inner_target_type, schema)
        end
      end
      def cast_param(value, %Absinthe.Type.InputObject{} = target_type, schema) when is_map(value) do
        for {name, field_value} <- value, into: %{} do
          case Map.values(target_type.fields) |> Enum.find(&(to_string(&1.identifier) == name)) do
            nil ->
              # Pass through value for error reporting by validations
              {name, field_value}
            field ->
              {
                name,
                cast_param(field_value, Absinthe.Schema.lookup_type(schema, field.type), schema)
              }
          end
        end
      end
      def cast_param(value, %Absinthe.Type.Scalar{__reference__: %{identifier: :integer}}, _schema) when is_binary(value) do
        case Integer.parse(value) do
          {result, _} ->
            result
          :error ->
            # Pass through value for error reporting by validations
            value
        end
      end
      def cast_param(value, %Absinthe.Type.Scalar{__reference__: %{identifier: :float}}, _schema) when is_binary(value) do
        case Float.parse(value) do
          {result, _} ->
            result
          :error ->
            # Pass through value for error reporting by validations
            value
        end
      end
      def cast_param(value, target_type, schema) do
        value
      end
      defoverridable [cast_param: 3]

    end
  end

  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :graphql_actions)
    provides = for {name, doc, _} <- actions, do: {name, doc}
    schemas = for {name, _, schema} <- actions, do: {to_string(name), schema}
    quote do

      defmodule GraphQL do
        use Absinthe.Plug.DocumentProvider.Compiled
        provide unquote(provides)

        @absinthe_schemas %{unquote_splicing(schemas)}
        def lookup_schema(name) do
          @absinthe_schemas[name]
        end

      end

    end
  end

  def register_graphql_action(env, :def, name, _args, _guards, _body) do
    default_schema = Module.get_attribute(env.module, :absinthe_schema)
    case Module.get_attribute(env.module, :graphql) do
      nil ->
        :ok
      {document, schema} ->
        Module.delete_attribute(env.module,
          :graphql
        )
        Module.put_attribute(env.module,
          :graphql_actions, {name, document, schema}
        )
      document ->
        Module.delete_attribute(env.module,
          :graphql
        )
        Module.put_attribute(env.module,
          :graphql_actions, {name, document, default_schema}
        )
    end
  end
  def register_graphql_action(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end

  @callback cast_param(value :: any, target_type :: Absinthe.Type.t, schema :: Absinthe.Schema.t) :: any

end
