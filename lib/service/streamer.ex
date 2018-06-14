defmodule Eventos.Service.Streamer do
  @moduledoc """
  # Streamer

  Handles streaming activities
  """

  use GenServer
  require Logger
  alias Eventos.Accounts.Actor

  def init(args) do
    {:ok, args}
  end

  def start_link do
    spawn(fn ->
      # 30 seconds
      Process.sleep(1000 * 30)
      GenServer.cast(__MODULE__, %{action: :ping})
    end)

    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_socket(topic, socket) do
    GenServer.cast(__MODULE__, %{action: :add, socket: socket, topic: topic})
  end

  def remove_socket(topic, socket) do
    GenServer.cast(__MODULE__, %{action: :remove, socket: socket, topic: topic})
  end

  def stream(topic, item) do
    GenServer.cast(__MODULE__, %{action: :stream, topic: topic, item: item})
  end

  def handle_cast(%{action: :ping}, topics) do
    topics
    |> Map.values()
    |> List.flatten()
    |> Enum.each(fn socket ->
      Logger.debug("Sending keepalive ping")
      send(socket.transport_pid, {:text, ""})
    end)

    spawn(fn ->
      # 30 seconds
      Process.sleep(1000 * 30)
      GenServer.cast(__MODULE__, %{action: :ping})
    end)

    {:noreply, topics}
  end

  def handle_cast(%{action: :add, topic: topic, socket: socket}, sockets) do
    topic = internal_topic(topic, socket)
    sockets_for_topic = sockets[topic] || []
    sockets_for_topic = Enum.uniq([socket | sockets_for_topic])
    sockets = Map.put(sockets, topic, sockets_for_topic)
    Logger.debug fn ->
      "Got new conn for #{topic}"
    end
    {:noreply, sockets}
  end

  def handle_cast(%{action: :remove, topic: topic, socket: socket}, sockets) do
    topic = internal_topic(topic, socket)
    sockets_for_topic = sockets[topic] || []
    sockets_for_topic = List.delete(sockets_for_topic, socket)
    sockets = Map.put(sockets, topic, sockets_for_topic)
    Logger.debug fn ->
      "Removed conn for #{topic}"
    end
    {:noreply, sockets}
  end

  def handle_cast(m, state) do
    Logger.info("Unknown: #{inspect(m)}, #{inspect(state)}")
    {:noreply, state}
  end

  defp internal_topic("user", socket) do
    "user:#{socket.assigns[:user].id}"
  end

  defp internal_topic(topic, _), do: topic
end
