defmodule RandomWalker.Client do
  @moduledoc """
  `RandomWalker.Client` is a client for the `RandomWalker`
  """
  use GenServer
  require Logger 
  
  defstruct name: :random_walker_client,
            server_name: :random_walker,
            increments: 0,
            zeros: 0,
            decrements: 0,

  @type t :: %__MODULE__{
    name: atom(),
    server_name: atom(),
    increments: non_neg_integer(),
    zeros: non_neg_integer(),
    decrements: non_neg_integer()
  }

  @type opt ::
    {:name, atom()} |
    {:server_name, atom()}

  # API

  @spec start_link([opt()]) :: {:ok, pid()}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @spec connect(RandomWalker.Client, atom()) :: :ok
  def connect(client, server) do
    GenServer.call(client, {:connect, server})
  end

  @spec disconnect(RandomWalker.Client, atom()) :: :ok
  def disconnect(client, server) do
    GenServer.call(client, {:disconnect, server})
  end

  @spec stop(RandomWalker.Client) :: :ok 
  def stop(client) do
    GenServer.stop(client, :normal)
  end

  # TODO: Implementation

  @impl GenServer
  @spec init([opt()]) :: {:ok, t()}
  def init(opts) do
    state = struct(RandomWalker, opts)
    Logger.info("#{state.name} starting, state = #{inspect state}")
    {:ok, state}
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

  @impl GenServer
  @spec handle_info(term(), t()) :: {:noreply, t()}
  def handle_info(:generate, state) do
    %{number: n, clients: clients} = state
    new_n = n + Enum.random(-1..1)
    Logger.debug("number is #{new_n}")
    MapSet.to_list(clients) |> Enum.each(fn client -> send(client, {:number, new_n}) end)
    schedule_action(state.interval)
    {:noreply, %{state | number: new_n}}
  end

  # Private functions

  def schedule_action(interval) do
    Process.send_after(self(), :generate, interval)
  end
end
