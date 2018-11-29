defmodule Absinthe.Phoenix.Controller.Result do
  @moduledoc false

  # Produces data fit for external encoding from annotated value tree

  alias Absinthe.{Blueprint, Phase, Type}
  use Absinthe.Phase

  @spec run(Blueprint.t() | Phase.Error.t(), Keyword.t()) :: {:ok, map}
  def run(%Blueprint{} = bp, _options \\ []) do
    result = Map.merge(bp.result, process(bp))
    {:ok, %{bp | result: result}}
  end

  defp process(blueprint) do
    result =
      case blueprint.execution do
        %{validation_errors: [], result: result} ->
          {:ok, data(result, [])}

        %{validation_errors: errors} ->
          {:validation_failed, errors}
      end

    format_result(result)
  end

  defp format_result(:execution_failed) do
    %{data: nil}
  end

  defp format_result({:ok, {data, []}}) do
    %{data: data}
  end

  defp format_result({:ok, {data, errors}}) do
    errors = errors |> Enum.uniq() |> Enum.map(&format_error/1)
    %{data: data, errors: errors}
  end

  defp format_result({:validation_failed, errors}) do
    errors = errors |> Enum.uniq() |> Enum.map(&format_error/1)
    %{errors: errors}
  end

  defp format_result({:parse_failed, error}) do
    %{errors: [format_error(error)]}
  end

  defp data(%{errors: [_ | _] = field_errors}, errors), do: {nil, field_errors ++ errors}

  # Leaf
  defp data(%{value: nil}, errors), do: {nil, errors}

  defp data(%{value: value, emitter: emitter}, errors) do
    # Change: don't serialize scalars
    value =
      case Type.unwrap(emitter.schema_node.type) do
        %Type.Scalar{} ->
          value

        %Type.Enum{} ->
          value
      end

    {value, errors}
  end

  # Object
  defp data(%{fields: []} = result, errors) do
    {result.root_value, errors}
  end

  defp data(%{fields: fields, emitter: emitter, root_value: root_value}, errors) do
    with %{put: _} <- emitter.flags,
         true <- is_map(root_value) do
      {data, errors} = field_data(fields, errors)
      {Map.merge(root_value, data), errors}
    else
      false ->
        raise """
        Invalid use of `@put` directive.

        The `@put` directive can only be used on fields that return maps or lists
        of maps.
        """

      _ ->
        field_data(fields, errors)
    end
  end

  # List
  defp data(%{values: values}, errors), do: list_data(values, errors)

  defp list_data(fields, errors, acc \\ [])
  defp list_data([], errors, acc), do: {:lists.reverse(acc), errors}

  defp list_data([%{errors: errs} = field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    list_data(fields, errs ++ errors, [value | acc])
  end

  defp field_data(fields, errors, acc \\ [])
  defp field_data([], errors, acc), do: {Map.new(acc), errors}

  defp field_data([%Absinthe.Resolution{} = res | _], _errors, _acc) do
    raise """
    Found unresolved resolution struct!

    You probably forgot to run the resolution phase again.

    #{inspect(res)}
    """
  end

  defp field_data([field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    field_data(fields, errors, [{field_name(field.emitter), value} | acc])
  end

  # TODO: would prefer if the names / aliases were already atoms somehow
  defp field_name(%{alias: nil, name: name}), do: String.to_existing_atom(name)
  defp field_name(%{alias: name}), do: String.to_existing_atom(name)
  defp field_name(%{name: name}), do: String.to_existing_atom(name)

  defp format_error(%Phase.Error{locations: []} = error) do
    error_object = %{message: error.message}
    Map.merge(error.extra, error_object)
  end

  defp format_error(%Phase.Error{} = error) do
    error_object = %{
      message: error.message,
      locations: Enum.flat_map(error.locations, &format_location/1)
    }

    error_object =
      case error.path do
        [] -> error_object
        path -> Map.put(error_object, :path, path)
      end

    Map.merge(Map.new(error.extra), error_object)
  end

  defp format_location(%{line: line, column: col}) do
    [%{line: line || 0, column: col || 0}]
  end

  defp format_location(_), do: []
end
