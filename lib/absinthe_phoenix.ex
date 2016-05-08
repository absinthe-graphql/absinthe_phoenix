defmodule Absinthe.Phoenix do
  defmacro __using__(_) do
    quote do
      use Absinthe.Schema

      plug Absinthe.Phoenix
    end
  end

  def init(opts), do: opts

  def call(conn, opts) do
    IO.puts "yo"
    conn |> IO.inspect
  end
end
