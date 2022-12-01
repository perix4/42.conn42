defmodule Conn42.Responder do
  use GenServer

  def start_link(init_args \\ []) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}}
  end

  def handle_cast({:notify, pid}, state) do
    # some workload here
    :timer.sleep(500)

    send(pid, "Hi #{inspect(pid)}")

    {:noreply, state}
  end

  def handle_cast({:notify_sse, topic}, state) do
    if Map.has_key?(state, topic) do
      {:noreply, state}
    else
      Process.send_after(self(), {:sse_ping, topic}, 1000)
      {:noreply, Map.put(state, topic, 20)}
    end
  end

  def handle_info({:sse_ping, topic}, state) do
    iteration = Map.get(state, topic)

    dispatch(iteration, topic)

    if iteration == 0 do
      {:noreply, Map.delete(state, topic)}
    else
      Process.send_after(self(), {:sse_ping, topic}, 1000)
      {:noreply, Map.put(state, topic, iteration - 1)}
    end
  end

  def dispatch(num, topic) do
    sse_msg =
      case num do
        0 -> {:exit, format_sse("bye bye")}
        num -> {:msg, format_sse(num)}
      end

    Registry.dispatch(Conn42.Registry, topic, fn entries ->
      for {pid, _} <- entries do
        send(pid, sse_msg)
      end
    end)
  end

  def format_sse(num) when is_number(num) do
    "data: This is message num #{num}\n"
  end

  def format_sse(msg) do
    "data: #{msg}\n"
  end
end
