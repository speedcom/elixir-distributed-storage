defmodule KV.Registry do
  use GenServer

  @doc """
  Starts the regsitry
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end



end