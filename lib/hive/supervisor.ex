defmodule Hive.Supervisor do
  use Supervisor
  def add(args) do
    id = args
    |> List.first
    |> Atom.to_string
    |> String.replace_suffix("", "_#{UUID.uuid1()}")
    {id,
    {Hive.Supervisor, :start_link, args}, :permanent,
 :infinity, :supervisor, [Hive.Supervisor]}
  end

  def start_link(module, args) do
    Supervisor.start_link(__MODULE__, [module, args], [name: name(module)])
  end

  def init([module, args]) do
    children = [
      worker(Hive.Manager, [[module, args]])
    ]
    supervise(children, strategy: :one_for_one)
  end

  def name(module) do
    module
    |> Atom.to_string
    |> String.replace_suffix("", ".HiveSupervisor")
    |> String.to_atom
    |> IO.inspect
  end
end
