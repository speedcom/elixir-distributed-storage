defmodule KV.Registry do
  use GenServer

  @doc """
  Starts the regsitry
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

end