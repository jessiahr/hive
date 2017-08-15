defmodule Hive.Manager do
  use GenServer
  require Logger

  def start_link([module, args]) do
    GenServer.start_link(__MODULE__, [module, args], [name: name(module)])
  end

  def init([module, args]) do
    Logger.info "Starting Hive Manager! [#{module}](#{args})"
    start([module, args])
    {:ok, [module, args]}
  end

  def start([module, []]) do
    Logger.info "Starting Hive Worker! [#{module}](NOARGS)"
    {status, pid} = module.start_link()
    Process.monitor(pid)
  end

  def start([module, args]) do
    Logger.info "Starting Hive Worker! [#{module}](#{args})"
    {status, pid} = module.start_link(args)
    Process.monitor(pid)
  end

  def name(module) do
    module
    |> Atom.to_string
    |> String.replace_suffix("", ".HiveManager")
    |> String.to_atom
  end

  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
    # Managed process exited normally. Shut manager down as well.
    IO.puts "Managed process exited normally. Shut manager down as well"
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _, :process, pid, :noconnection}, state) do
    IO.puts "Managed process is nolonger reachable. Restarting on this node."
    start(state)
    {:noreply, nil}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, state) do
    IO.puts "Managed process exited with an error(#{reason}). Try restarting."
    start(state)
    {:noreply, nil}
  end

end
