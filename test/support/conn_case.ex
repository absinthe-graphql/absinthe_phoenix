defmodule Absinthe.Phoenix.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      @endpoint Absinthe.Phoenix.TestEndpoint
    end
  end
end
