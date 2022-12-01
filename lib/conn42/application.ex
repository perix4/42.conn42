defmodule Conn42.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Conn42.Registry},
      Conn42.Responder,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Conn42.Router,
        options: [port: 4005]
      )
    ]

    opts = [strategy: :one_for_one, name: Conn42.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
