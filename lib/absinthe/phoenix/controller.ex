defmodule Absinthe.Phoenix.Controller do
  @moduledoc """
  Supports use of GraphQL documents inside Phoenix controllers.

  ## Example

  First, `use Absinthe.Phoenix.Controller`, passing your `schema`:

  ```elixir
  defmodule MyAppWeb.UserController do
    use MyAppWeb, :controller
    use Absinthe.Phoenix.Controller, schema: MyAppWeb.Schema

    # ... actions

  end
  ```

  For each action you want Absinthe to process, provide a GraphQL document using
  the `@graphql` module attribute (before the action):

  ```
  @graphql \"""
    query ($filter: UserFilter) {
      users(filter: $filter, limit: 10)
    }
  \"""
  def index(conn, %{data: data}) do
    render conn, "index.html", data
  end
  ```

  The params for the action will be intercepted by the
  `Absinthe.Phoenix.Controller.Action` plug, and used as variables for
  the GraphQL document you've specified.

  For instance, given a definition for a `:user_filter` input object
  type like this:

  ```
  input_object :user_filter do
    field :name_matches, :string
    field :age_above, :integer
    field :age_below, :integer
  end
  ```

  And a query that looks like this (assuming you have the normal
  `Plug.Parsers` configuration for param parsing):

  ```
  ?filter[name_matches]=joe&filter[age_above]=42
  ```

  Then Absinthe will receive variable definitions of:

  ```
  %{"filter" => %{"name_matches" => "joe", "age_above" => 42}}
  ```

  (For how the string `"42"` was converted into `42`, see `cast_param/3`).

  The params on the `conn` will then be replaced by the result of the
  execution by Absinthe. The action function can then match against
  that result to respond correctly to the user:

  It's up to you to handle the three possible results:

  - When there's `:data` but no `:errors`, everything went perfectly.
  - When there's `:errors` but no `:data`, a validation error occurred and the document could not be
    executed.
  - When there's `:data` and `:errors`, partial data is available but some fields reported errors
    during execution.

  Notice the keys are atoms, not strings as in normal Phoenix action invocations.

  ## Differences with the GraphQL Specification

  There are some important differences between GraphQL documents as
  processed in an HTTP API and the GraphQL documents that this module
  supports.

  In an effort to make use of GraphQL ergonomic in Phoenix controllers
  and views, Absinthe supports some slight structural modifications to
  the GraphQL documents provided using the `@graphql` module attribute
  in controller modules.

  In a way, you can think of these changes as a specialized GraphQL
  dialect. The following are the differences you need to keep in mind.

  ### Objects can be leaf nodes

  Let's look at the `users` example mentioned before:

  ```
  @graphql \"""
    query ($filter: UserFilter) {
      users(filter: $filter, limit: 10)
    }
  \"""
  ```

  You'll notice that in the above example, `users` doesn't have an
  accompanying _selection set_ (that is, a set of child fields bounded
  by `{ ... }`). The GraphQL specification dictates that only scalar
  values can be "leaf nodes" in a GraphQL document... but to support
  unmodified struct values being returned (for example, Ecto schemas),
  if no selection set is provided for an object value (or list
  thereof), the entire value is returned.

  The template can then use `users` as needed:

  ```
  <ul>
    <%= for user <- @users do %>
      <li><%= link user.full_name, to: user_path(@conn, :show, user) %></li>
    <% end %>
  </ul>
  ```

  This is useful for `Phoenix.HTML` helper functions that expect
  structs with specific fields (especially `form_for`).

  One way to think of this change is that, for objects, no selection
  set is equivalent to a "splat" operator (except, of course, even
  fields not defined in your GraphQL schema are returned as part of
  the value).

  But, never fear, nothing is stopping you from ignoring this behavior
  and providing a selection set if you want a traditionally narrow set
  of fields:

  ```
  @graphql \"""
    query ($filter: UserFilter) {
      users(filter: $filter, limit: 10) {
        id
        full_name
      }
    }
  \"""
  ```

  ### Scalar values aren't serialized

  To remove the need for reparsing values, scalar values aren't serialized;
  Phoenix actions receive the original, unserialized values of GraphQL fields.

  This is especially useful for custom scalar types. Using a couple of the
  additional types packaged in `Absinthe.Type.Custom`, for example:

  - `:decimal` values are returned as `%Decimal{}` structs, not strings.
  - `:datetime` values are returned as `%DateTime{}` structs, not strings.

  In short, GraphQL used in controllers is a query language to retrieve the values requested---there's no need to serialize the
  values to send them across HTTP.

  ### Fields use snake_case

  Unlike in the GraphQL notation scheme we prefer for GraphQL APIs (that is,
  `camelCase` fields, which better match up with the expectations of JavaScript
  clients), fields used in documents provided as `@graphql` should use
  `snake_case` naming, as Elixir conventions use that notation style for atoms,
  etc.

  ### Atom keys

  Because you are writing the GraphQL document in your controller and Absinthe
  is validating the document against your schema, atom keys are returned for
  field names.
  """

  defmacro __using__(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @on_definition {unquote(__MODULE__), :register_graphql_action}
      Module.register_attribute(__MODULE__, :graphql_actions, accumulate: true)
      import unquote(__MODULE__), only: [variables: 1]

      @absinthe_schema unquote(schema)

      plug(unquote(__MODULE__).Action, unquote(opts))

      @impl unquote(__MODULE__)
      @spec cast_param(
              value :: any,
              target_type :: Absinthe.Type.t(),
              schema :: Absinthe.Schema.t()
            ) :: any
      def cast_param(value, %Absinthe.Type.NonNull{of_type: inner_target_type}, schema) do
        cast_param(value, inner_target_type, schema)
      end

      def cast_param(values, %Absinthe.Type.List{of_type: inner_target_type}, schema)
          when is_list(values) do
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

      def cast_param(
            value,
            %Absinthe.Type.Scalar{__reference__: %{identifier: :integer}},
            _schema
          )
          when is_binary(value) do
        case Integer.parse(value) do
          {result, _} ->
            result

          :error ->
            # Pass through value for error reporting by validations
            value
        end
      end

      def cast_param(value, %Absinthe.Type.Scalar{__reference__: %{identifier: :float}}, _schema)
          when is_binary(value) do
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

      defoverridable cast_param: 3

      @impl unquote(__MODULE__)
      @spec absinthe_pipeline(schema :: Absinthe.Schema.t(), Keyword.t()) :: Absinthe.Pipeline.t()
      def absinthe_pipeline(schema, opts) do
        unquote(__MODULE__).default_pipeline(schema, opts)
      end

      defoverridable absinthe_pipeline: 2
    end
  end

  def variables(conn) do
    conn.private[:absinthe_variables]
  end

  def default_pipeline(schema, options) do
    alias Absinthe.{Phase, Pipeline}
    options = Pipeline.options(options)

    schema
    |> Pipeline.for_document(options)
    |> Pipeline.from(Phase.Document.Variables)
    |> Pipeline.insert_before(
      Phase.Document.Variables,
      {Absinthe.Phoenix.Controller.Blueprint, options}
    )
    |> Pipeline.without(Phase.Document.Validation.ScalarLeafs)
    |> Pipeline.insert_after(
      Phase.Document.Directives,
      {Absinthe.Phoenix.Controller.Action, options}
    )
  end

  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :graphql_actions)
    provides = for {name, doc, _} <- actions, do: {name, doc}
    schemas = for {name, _, schema} <- actions, do: {to_string(name), schema}

    quote do
      defmodule GraphQL do
        use Absinthe.Plug.DocumentProvider.Compiled
        provide(unquote(provides))

        @absinthe_schemas %{unquote_splicing(schemas)}
        def lookup_schema(name) do
          @absinthe_schemas[name]
        end
      end
    end
  end

  @doc false
  def register_graphql_action(env, :def, name, _args, _guards, _body) do
    default_schema = Module.get_attribute(env.module, :absinthe_schema)

    case Module.get_attribute(env.module, :graphql) do
      nil ->
        :ok

      {document, schema} ->
        Module.delete_attribute(env.module, :graphql)
        Module.put_attribute(env.module, :graphql_actions, {name, document, schema})

      document ->
        Module.delete_attribute(env.module, :graphql)
        Module.put_attribute(env.module, :graphql_actions, {name, document, default_schema})
    end
  end

  def register_graphql_action(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end

  @doc """
  Cast string param values to values Absinthe expects for variable input.

  Some scalar types, like `:integer` (GraphQL `Int`) require that raw,
  incoming value be a non-string type. This isn't a problem in
  GraphQL-over-HTTP because the variable values are provided as a JSON
  payload (which supports, i.e., integer values).

  To support converting incoming param values to the format that
  certain scalars expect, we support a `cast_param/3` callback
  function that takes a raw value, target type (e.g., the scalar
  type), and the schema, and returns the transformed
  value. `cast_param/3` is overridable and the implementation already
  supports `:integer` and `:float` types.

  If you override `cast_param/3`, make sure you super or handle lists,
  non-nulls, and input object values yourself; they're also processed
  using the function.

  Important: In the event that a value is _invalid_, just return it
  unchanged so that Absinthe's usual validation logic can report it as
  invalid.
  """
  @callback cast_param(
              value :: any,
              target_type :: Absinthe.Type.t(),
              schema :: Absinthe.Schema.t()
            ) :: any

  @doc """
  Customize the Absinthe processing pipeline.

  Only implement this function if you need to change the pipeline used
  to process documents.
  """
  @callback absinthe_pipeline(schema :: Absinthe.Schema.t(), Keyword.t()) :: Absinthe.Pipeline.t()
end
