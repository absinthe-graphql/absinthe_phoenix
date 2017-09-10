defmodule Absinthe.Phoenix.Controller do

  defmacro __using__(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @on_definition {unquote(__MODULE__), :register_graphql_action}
      Module.register_attribute(__MODULE__, :graphql_actions, accumulate: true)

      plug unquote(__MODULE__).Action, document_provider: __MODULE__.GraphQL, schema: unquote(schema)

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
