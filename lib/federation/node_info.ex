defmodule Mobilizon.Federation.NodeInfo do
  @moduledoc """
  Performs NodeInfo requests
  """

  alias Mobilizon.Service.HTTP.WebfingerClient
  require Logger

  @application_uri "https://www.w3.org/ns/activitystreams#Application"
  @nodeinfo_rel_2_0 "http://nodeinfo.diaspora.software/ns/schema/2.0"
  @nodeinfo_rel_2_1 "http://nodeinfo.diaspora.software/ns/schema/2.1"

  @env Application.compile_env(:mobilizon, :env)

  @spec application_actor(String.t()) :: String.t() | nil
  def application_actor(host) do
    Logger.debug("Fetching application actor from NodeInfo data for domain #{host}")

    case fetch_nodeinfo_endpoint(host) do
      {:ok, body} ->
        extract_application_actor(body)

      {:error, :node_info_meta_http_error} ->
        nil
    end
  end

  @spec nodeinfo(String.t()) :: {:ok, map()} | {:error, atom()}
  def nodeinfo(host) do
    Logger.debug("Fetching NodeInfo details for domain #{host}")

    with {:ok, endpoint} when is_binary(endpoint) <- fetch_nodeinfo_details(host),
         :ok <- Logger.debug("Going to get NodeInfo information from URL #{endpoint}"),
         {:ok, %{body: body, status: code}} when code in 200..299 <- WebfingerClient.get(endpoint) do
      Logger.debug("Found nodeinfo information for domain #{host}")
      {:ok, body}
    else
      {:error, err} ->
        {:error, err}

      err ->
        Logger.debug("Failed to fetch NodeInfo data from endpoint #{inspect(err)}")
        {:error, :node_info_endpoint_http_error}
    end
  end

  defp extract_application_actor(body) do
    body
    |> Map.get("links", [])
    |> Enum.find(%{"rel" => @application_uri, "href" => nil}, fn %{"rel" => rel, "href" => href} ->
      rel == @application_uri and is_binary(href)
    end)
    |> Map.get("href")
  end

  @spec fetch_nodeinfo_endpoint(String.t()) :: {:ok, map()} | {:error, atom()}
  defp fetch_nodeinfo_endpoint(host) do
    prefix = if @env !== :dev, do: "https", else: "http"

    case WebfingerClient.get("#{prefix}://#{host}/.well-known/nodeinfo") do
      {:ok, %{body: body, status: code}} when code in 200..299 ->
        {:ok, body}

      err ->
        Logger.debug("Failed to fetch NodeInfo data #{inspect(err)}")
        {:error, :node_info_meta_http_error}
    end
  end

  @spec fetch_nodeinfo_details(String.t()) :: {:ok, String.t()} | {:error, atom()}
  defp fetch_nodeinfo_details(host) do
    with {:ok, body} <- fetch_nodeinfo_endpoint(host) do
      extract_nodeinfo_endpoint(body)
    end
  end

  @spec extract_nodeinfo_endpoint(map()) ::
          {:ok, String.t()}
          | {:error, :no_node_info_endpoint_found | :no_valid_node_info_endpoint_found}
  defp extract_nodeinfo_endpoint(body) do
    links = Map.get(body, "links", [])

    relation =
      find_nodeinfo_relation(links, @nodeinfo_rel_2_1) ||
        find_nodeinfo_relation(links, @nodeinfo_rel_2_0)

    if is_nil(relation) do
      {:error, :no_node_info_endpoint_found}
    else
      endpoint = Map.get(relation, "href")

      if is_nil(endpoint) do
        {:error, :no_valid_node_info_endpoint_found}
      else
        {:ok, endpoint}
      end
    end
  end

  defp find_nodeinfo_relation(links, relation) do
    Enum.find(links, fn %{"rel" => rel, "href" => href} ->
      rel == relation and is_binary(href)
    end)
  end
end
