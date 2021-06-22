defmodule Absinthe.Phoenix.Presence do
  @moduledoc """
  This module is to allow the use of the Phoenix.Presence behaviour (https://hexdocs.pm/phoenix/Phoenix.Presence.html) while using Absinthe.Phoenix.

  To use it, do the following:
  1. Set up your implementation of Phoenix.Presence as per the official documentation: https://hexdocs.pm/phoenix/Phoenix.Presence.html
  2. When 'using' Absinthe.Phoenix.Socket, simply add the presence_config option like so:
      '''
      defmodule MyAppWeb.SocketUserModule do
          use Absinthe.Phoenix.Socket,
              presence_config: %{
                  module: MyAppWeb.Presence,
                  meta_fn: &some_meta_logic_fn/1,
                  key_fn: &some_key_logic_fn/1
              }
          
          ...
      end
      '''
      *   The some_meta_logic/1 function is a function that returns the `meta` argument that Phoenix.Presence.track/3 expects (see https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3 for more info).
          The argument should be socket itself, which is of type `Phoenix.Socket`. The reason it is a function and not a single data item is that it allows the devloper to be
          flexible and apply/get whatever meta logic/data they want from the socket
      *   The some_key_logic_fn/1 function is a function that returns the `key` argument that Phoenix.Presence.track/3 expects (see https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3 for more info).
          The argument should be socket itself, which is of type `Phoenix.Socket`. The reason it is a function and not a single data item is that it allows the devloper to be
          flexible and apply/get whatever key logic/data they want from the socket        
  """
  require Logger
  @presence_topic "__absinthe__:control"

  def presence_topic() do
    @presence_topic
  end

  @doc """
  Function to call the Phoenix.Presence.track/3 callback from the module that the user has configured in __absinthe_presence_config__.
  """
  def track(socket = %{assigns: %{__absinthe_presence_config__: presence_config}})
      when is_map(presence_config) do
    module = Map.get(presence_config, :module, __MODULE__.Defaults)
    meta_fn = Map.get(presence_config, :meta_fn, &__MODULE__.Defaults.meta_fn/1)
    key_fn = Map.get(presence_config, :key_fn, &__MODULE__.Defaults.key_fn/1)

    {:ok, _} = module.track(socket, key_fn.(socket), meta_fn.(socket))
  end

  def track(_socket) do
    Logger.warn(
      "Cannot track as socket.assigns does not contain a valid :__abinthe_presence_config__ key!"
    )

    nil
  end

  @doc """
  Function to call the Phoenix.Presence.list/1 callback from the module that the user has configured in __absinthe_presence_config__.
  """
  def list(socket = %{assigns: %{__absinthe_presence_config__: presence_config}})
      when is_map(presence_config) do
    module = Map.get(presence_config, :module)

    if module == nil do
      Logger.warn(
        "Cannot list as the :__abinthe_presence_config__ map does not contain a :module key!"
      )

      nil
    else
      module.list(socket)
    end
  end

  def list(_socket) do
    Logger.warn(
      "Cannot list as socket.assigns does not contain a valid :__abinthe_presence_config__ key!"
    )

    nil
  end

  defmodule Defaults do
    @moduledoc """
    Module for housing the default functions if none are given
    """
    def track(_socket, _key, _meta) do
      {:ok, ""}
    end

    def meta_fn(_socket) do
      %{
        online_at: inspect(System.system_time(:second))
      }
    end

    def key_fn(_socket) do
      ""
    end
  end
end
