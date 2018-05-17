defmodule Eventos.Application do
  @moduledoc """
  The Eventos application
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Eventos.Repo, []),
      # Start the endpoint when the application starts
      supervisor(EventosWeb.Endpoint, []),
      # Start your own worker by calling: Eventos.Worker.start_link(arg1, arg2, arg3)
      # worker(Eventos.Worker, [arg1, arg2, arg3]),
      worker(Guardian.DB.Token.SweeperServer, []),
      worker(Eventos.Service.Federator, []),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Eventos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EventosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
