defmodule RandomWalker.Client do
  @moduledoc """
  `RandomWalker.Client` is a client for the `RandomWalker`
  """
  use GenServer
  require Logger 
  
  defstruct name: :random_walker_client,
            server_name: :random_walker,
            step: 0,
            number: 0,
            increments: 0,
            zeros: 0,
            decrements: 0

  @type t :: %__MODULE__{
    name: atom(),
    server_name: atom(),
    step: non_neg_integer(),
    number: integer(),
    increments: non_neg_integer(),
    zeros: non_neg_integer(),
    decrements: non_neg_integer()
  }

  @type opt ::
    {:name, atom()} |
    {:server_name, atom()}

  # Client API

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

  # Server implementation
  
  @impl GenServer
  @spec init([opt()]) :: {:ok, t()}
  def init(opts) do
    state = struct(RandomWalker.Client, opts)
    Logger.info("#{state.name} starting, state = #{inspect state}")
    {:ok, state}
  end

  @impl GenServer
  @spec handle_call(term(), GenServer.from(), t()) :: {:reply, :ok, t()}
  def handle_call({:connect, server}, _from, state) do
    server_pid = :global.whereis_name(server)
    result = RandomWalker.register(server_pid)
    {:reply, result, state}
  end

  def handle_call({:unregister, server}, _from, state) do
    server_pid = :global.whereis_name(server)
    result = RandomWalker.unregister(server_pid)
    {:reply, result, state}
  end

  @impl GenServer
  @spec handle_info(term(), t()) :: {:noreply, t()}
  def handle_info({:random_walk, _name, step, number}, state) do
    state = update_state(state, step, number)
    Logger.info(":random_walk #{state}")
    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, state) do
    %{name: name} = state
    Logger.info("#{name} stopping, reason #{reason}")
  end

# Private 

  @spec update_state(t(), non_neg_integer(), integer()) :: t()
  defp update_state(state, step, number) do
    %{number: last_number, decrements: d, zeros: z, increments: i} = state
    case number - last_number do
      -1 ->
        %{state | step: step, number: number, decrements: d + 1}
      0 ->
        %{state | step: step, number: number, zeros: z + 1}
      1 ->
        %{state | step: step, number: number, increments: i + 1}
    end
  end
end
