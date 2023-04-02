defmodule ChatGPT.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ChatGPT.Release.migrate()
    children = [
      # Start the Telemetry supervisor
      ChatGPTWeb.Telemetry,
      # Start the Ecto repository
      ChatGPT.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ChatGPT.PubSub},
      # Start Finch
      {Finch, name: ChatGPT.Finch, pools: %{:default => [size: 10]}},
      # Start the Endpoint (http/https)
      ChatGPTWeb.Endpoint
      # Start a worker by calling: ChatGPT.Worker.start_link(arg)
      # {ChatGPT.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatGPT.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatGPTWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
