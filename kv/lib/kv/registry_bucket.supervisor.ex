defmodule KV.RegistryBucket.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @bucket_sup_name KV.Bucket.Supervisor
  @registry_name   KV.Registry
  @manager_name    KV.EventManager

  def init(:ok) do
    children = [
      supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
      worker(KV.Registry, [@bucket_sup_name, [name: @registry_name]])
    ]

    supervise(children, strategy: :one_for_all)
  end

end