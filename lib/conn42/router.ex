defmodule Conn42.Router do
  use Plug.Router
  plug(:match)
  plug(:dispatch)

  get "event" do
    GenServer.cast(Conn42.Responder, {:notify, self()})

    receive do
      msg ->
        conn
        |> send_resp(200, msg)
    after
      5_000 ->
        conn
        |> send_resp(503, "Oh noes!")
    end
  end

  get "sse-event" do
    conn = fetch_query_params(conn)
    topic = conn.query_params["id"]

    {:ok, _} = Registry.register(Conn42.Registry, topic, [])
    GenServer.cast(Conn42.Responder, {:notify_sse, topic})

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.put_resp_header("content-encoding", "identity")
    |> Plug.Conn.send_chunked(200)
    |> listen()
  end

  defp listen(conn) do
    receive do
      {:msg, msg} ->
        {:ok, conn} = Plug.Conn.chunk(conn, msg)

        listen(conn)

      {:exit, msg} ->
        {:ok, conn} = Plug.Conn.chunk(conn, msg)

        Plug.Conn.halt(conn)
    end
  end
end
