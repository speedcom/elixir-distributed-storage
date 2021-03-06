defmodule KV.Registry do
  use GenServer

  @doc """
  Starts the regsitry
  """
  def start_link(event_manager, bucket_sup, opts \\ []) do
    GenServer.start_link(__MODULE__, {event_manager, bucket_sup}, opts)
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

  def init({events, bucket_sup}) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, %{names: names, refs: refs, events: events, bucket_sup: bucket_sup}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, HashDict.fetch(state.names, name), state}
  end

  def handle_cast({:create, name}, state) do
    if HashDict.has_key?(state.names, name) do
      {:noreply, state}
    else
      {:ok, bucket} = KV.Bucket.Supervisor.start_bucket(state.bucket_sup)
      monit = Process.monitor(bucket)
      refs  = HashDict.put(state.refs, monit, name)
      names = HashDict.put(state.names, name, bucket)

      GenEvent.sync_notify(state.events, {:create, name, bucket})

      {:noreply, %{state | names: names, refs: refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    names = HashDict.delete(state.names, name)

    GenEvent.sync_notify(state.events, {:exit, name, pid})

    {:noreply, %{state | names: names, refs: refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end