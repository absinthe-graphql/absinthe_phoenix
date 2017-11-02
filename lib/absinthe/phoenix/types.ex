defmodule Absinthe.Phoenix.Types do
  use Absinthe.Schema.Notation

  directive :put do
    on [:field, :fragment_spread, :inline_fragment]
    expand fn
      _args, node ->
        Absinthe.Blueprint.put_flag(node, :put, __MODULE__)
    end
  end
end
