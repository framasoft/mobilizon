defmodule Mobilizon.Federation.NodeInfo do
  @moduledoc """
  Performs NodeInfo requests
  """

  alias Mobilizon.Service.HTTP.WebfingerClient
  require Logger

  @application_uri "https://www.w3.org/ns/activitystreams#Application"
  @env Application.compile_env(:mobilizon, :env)

  @spec application_actor(String.t()) :: String.t() | nil
  def application_actor(host) do
    prefix = if @env !== :dev, do: "https", else: "http"

    case WebfingerClient.get("#{prefix}://#{host}/.well-known/nodeinfo") do
      {:ok, %{body: body, status: code}} when code in 200..299 ->
        extract_application_actor(body)

      err ->
        Logger.debug("Failed to fetch NodeInfo data #{inspect(err)}")
        nil
    end
  end

  defp extract_application_actor(body) do
    body
    |> Enum.find(%{rel: @application_uri, href: nil}, fn %{rel: rel, href: href} ->
      rel == @application_uri and is_binary(href)
    end)
    |> Map.get(:href)
  end
end
