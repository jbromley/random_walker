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
            decrements: 0

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
  def handle_call({:connect, server}, {pid, _} = _from, state) do
    # TODO: connect to a RandomWalker server.
  end

  def handle_call({:unregister, server}, {pid, _} = _from, state) do
    Logger.debug("#{state.name} removing client #{inspect pid}")
    # TODO: disconnect from a RandomWalker server  
  end

  @impl GenServer
  @spec handle_info(term(), t()) :: {:noreply, t()}
  def handle_info(:generate, state) do
    # TODO: Handle receiving messages from the RandomWalker server.
    # {:noreply, %{state | number: new_n}}
  end

  @impl GenServer
  def terminate(reason, state) do
    %{name: name} = state
    Logger.info("#{name} stopping, reason #{reason}")
  end
end
