defmodule Hive.Manager do
  use GenServer
  require Logger

  def start_link([module, args]) do
    GenServer.start_link(__MODULE__, [module, args], [name: name(module)])
  end

  def init([module, args]) do
    Logger.info "Hive.Manager Starting [#{module}](#{args}) on #{node()}!"
    Process.flag(:trap_exit, true)
    start([module, args])
    {:ok, [module, args]}
  end

  def start([module, args]) do
    Logger.info "Hive.Worker Starting [#{module}](#{args}) on #{node()}!"
    case apply(module, :start_link, args) do
      {status, pid} ->
        Process.monitor(pid)
    end
  end

  def name(module) do
    module
    |> Atom.to_string
    |> String.replace_suffix("", ".HiveManager")
    |> String.to_atom
  end

  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
    # Managed process exited normally. Shut manager down as well.
    IO.puts "Hive.Worker exited normally. Shut manager down as well"
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _, :process, pid, :noconnection}, state) do
    Logger.info "Hive.Worker is nolonger reachable. Restarting on this node."
    IO.inspect state
    start(state)
    {:noreply, nil}
  end

  def handle_info({:EXIT, _, :killed}, state = [module, args]) do
    Logger.info "Hive.Worker killed [#{module}](#{args}) on #{node()}!"
    {:stop, :normal, state}
 end

 def handle_info({:EXIT, _, :killed}, state) do
    IO.inspect state
    Logger.info "Hive.Worker killed (no state)[]() on #{node()}!"
    {:stop, :normal, state}
  end
end
