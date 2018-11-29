defmodule Absinthe.Phoenix.Types do
  use Absinthe.Schema.Notation

  directive :put do
    on [:field, :fragment_spread, :inline_fragment]

    expand fn _args, node ->
      Absinthe.Blueprint.put_flag(node, :put, __MODULE__)
    end
  end

  directive :action do
    on [:query, :mutation, :subscription]
    arg :mode, non_null(:action_mode)

    expand fn %{mode: mode}, node ->
      Absinthe.Blueprint.put_flag(node, {:action, mode}, __MODULE__)
    end
  end

  enum :action_mode do
    value :internal
    value :external
  end
end
