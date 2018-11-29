defmodule Absinthe.Phoenix.TestSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket

  def connect(_, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_), do: nil
end
