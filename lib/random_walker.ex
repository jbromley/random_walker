defmodule RandomWalker do
  @moduledoc """
  `RandomWalker` does a random walk and broadcasts the current value
  """
  use GenServer
  require Logger 
  
  @derive Inspect
  defstruct name: :random_walker,
            interval: 1_000,
            start: 0,
            number: 0,
            clients: MapSet.new()

  @type t :: %__MODULE__{
    name: atom(),
    interval: non_neg_integer(),
    start: integer(),
    clients: MapSet.t(pid())
  }

  @type opt ::
    {:name, atom()} |
    {:interval, non_neg_integer()} |
    {:start, integer()}

  # API

  @spec start_link([opt()]) :: {:ok, pid()}
  def start_link(opts \\ []) do
    name = opts[:name]
    GenServer.start_link(__MODULE__, opts, name: {:global, name})
  end

  @spec register(RandomWalker) :: :ok
  def register(server) do
    GenServer.call(server, :register)
  end

  @spec unregister(RandomWalker) :: :ok
  def unregister(server) do
    GenServer.call(server, :unregister)
  end

  @spec log(RandomWalker) :: :ok
  def log(server) do
    GenServer.call(server, :log)
  end

  @spec stop(RandomWalker) :: :ok 
  def stop(server) do
    GenServer.stop(server, :normal)
  end

  # Implementation

  @impl GenServer
  @spec init([opt()]) :: {:ok | {:ok, t()}, t()}
  def init(opts) do
    state = struct(RandomWalker, opts)
    schedule_action(state.interval)
    Logger.info("#{state.name} starting, state = #{inspect state}")
    {:ok, %{state | number: state.start}}
  end

  @impl GenServer
  @spec handle_call(term(), GenServer.from(), t()) :: {:reply, :ok, t()}
  def handle_call(:register, {pid, _} = _from, state) do
    Logger.debug("#{state.name} adding client #{inspect pid}")
    {:reply, :ok, %{state | clients: MapSet.put(state.clients, pid)}}
  end

  def handle_call(:unregister, {pid, _} = _from, state) do
    Logger.debug("#{state.name} removing client #{inspect pid}")
    {:reply, :ok, %{state | clients: MapSet.delete(state.clients, pid)}}
  end

  def handle_call{:log, _from, state} do
    Logger.info("#{inspect state}")
    {:reply, {:ok, state}, state}
  end

  @impl GenServer
  @spec handle_info(term(), t()) :: {:noreply, t()}
  def handle_info(:generate, state) do
    %{name: name, number: n, clients: clients} = state
    new_n = n + Enum.random(-1..1)
    Logger.debug("number is #{new_n}")
    MapSet.to_list(clients) |> Enum.each(fn client -> send(client, {name, :number, new_n}) end)
    schedule_action(state.interval)
    {:noreply, %{state | number: new_n}}
  end

  # Private functions

  def schedule_action(interval) do
    Process.send_after(self(), :generate, interval)
  end
end
