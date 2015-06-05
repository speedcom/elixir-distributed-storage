defmodule KV.Registry do
  use GenServer

  @doc """
  Starts the regsitry
  """
  def start_link(event_bus, opts \\ []) do
    GenServer.start_link(__MODULE__, event_bus, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures that pid with `name` is stored in `server`
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  @doc """
  Stop the server
  """
  def stop(server) do
    GenServer.call(server, :stop)
  end


  ##Server Callbacks

  def init(events) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, %{names: names, refs: refs, events: events}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, HashDict.fetch(state.names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
    if HashDict.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link
      ref = Process.monitor(bucket)
      refs = HashDict.put(refs, ref, name)
      names = HashDict.put(names, name, bucket)
      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = HashDict.pop(refs, ref)
    names = HashDict.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end