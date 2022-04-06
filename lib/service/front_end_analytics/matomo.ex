defmodule Mobilizon.Service.FrontEndAnalytics.Matomo do
  @moduledoc """
  Matomo analytics provider
  """
  alias Mobilizon.Service.FrontEndAnalytics
  @behaviour FrontEndAnalytics

  @impl FrontEndAnalytics
  def id, do: "matomo"

  @doc """
  Whether the service is enabled
  """
  @impl FrontEndAnalytics
  def enabled? do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:enabled, false)
  end

  @doc """
  The configuration for the service
  """
  @impl FrontEndAnalytics
  def configuration do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.drop([:enabled, :csp])
  end

  @doc """
  The CSP configuration to add for the service to work
  """
  @impl FrontEndAnalytics
  def csp do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:csp, [])
  end
end
