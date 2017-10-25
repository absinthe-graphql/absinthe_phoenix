defmodule Absinthe.Phoenix.ConnCase do

  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      @endpoint Absinthe.Phoenix.TestEndpoint
    end
  end

end
