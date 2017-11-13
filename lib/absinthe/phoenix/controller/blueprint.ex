defmodule Absinthe.Phoenix.Controller.Blueprint do
  @moduledoc false

  # make sure to set values on blueprint
  def run(blueprint, options) do
    context = Map.merge(blueprint.execution.context, options[:context] || %{})
    blueprint = put_in(blueprint.execution.context, context)

    root_value = Map.merge(blueprint.execution.root_value, options[:root_value] || %{})
    blueprint = put_in(blueprint.execution.root_value, root_value)

    {:ok, blueprint}
  end
end
