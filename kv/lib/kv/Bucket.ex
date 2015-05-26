defmodule KV.Bucket do

  @@doc """
  Starts a new bucket
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

end