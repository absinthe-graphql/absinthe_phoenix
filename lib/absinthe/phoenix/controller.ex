defmodule Absinthe.Phoenix.Controller do

  defmacro __using__(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)
    quote do
      @before_compile unquote(__MODULE__)
      @on_definition {unquote(__MODULE__), :register_graphql_action}
      Module.register_attribute(__MODULE__, :graphql_actions, accumulate: true)

      plug unquote(__MODULE__).Action, schema: unquote(schema)

      @spec coerce_to_graphql_input(value :: any, target_type :: Absinthe.Type.t) :: any
      def coerce_to_graphql_input(value, %Absinthe.Type.NonNull{of_type: inner_target_type}) do
        coerce_to_graphql_input(value, inner_target_type)
      end
      def coerce_to_graphql_input(values, %Absinthe.Type.List{of_type: inner_target_type}) when is_list(values) do
        for value <- values do
          coerce_to_graphql_input(value, inner_target_type)
        end
      end
      def coerce_to_graphql_input(value, %Absinthe.Type.InputObject{} = target_type) when is_map(value) do
        for {name, field_value} <- value, into: %{} do
          case Map.get(target_type.fields, name) do
            nil ->
              # Pass through value for error reporting by validations
              {name, field_value}
            field ->
              {
                name,
                coerce_to_graphql_input(field_value, field.type)
              }
          end
        end
      end
      def coerce_to_graphql_input(value, %Absinthe.Type.Scalar{__reference__: %{identifier: :integer}}) when is_binary(value) do
        case Integer.parse(value) do
          {result, _} ->
            result
          :error ->
            # Pass through value for error reporting by validations
            value
        end
      end
      def coerce_to_graphql_input(value, %Absinthe.Type.Scalar{__reference__: %{identifier: :float}}) when is_binary(value) do
        case Float.parse(value) do
          {result, _} ->
            result
          :error ->
            # Pass through value for error reporting by validations
            value
        end
      end
      def coerce_to_graphql_input(value, target_type) do
        value
      end
      defoverridable [coerce_to_graphql_input: 2]

    end
  end

  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :graphql_actions)
    quote do

      defmodule GraphQL do
        use Absinthe.Plug.DocumentProvider.Compiled
        provide unquote(actions)
      end

    end
  end

  def register_graphql_action(env, :def, name, _args, _guards, _body) do
    case Module.get_attribute(env.module, :graphql) do
      nil ->
        :ok
      document ->
        Module.delete_attribute(env.module,
          :graphql
        )
        Module.put_attribute(env.module,
          :graphql_actions, {name, document}
        )
    end
  end
  def register_graphql_action(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end


end
