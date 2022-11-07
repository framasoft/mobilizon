defmodule Mobilizon.Service.Pictures.Unsplash do
  @moduledoc """
  [Unsplash](https://unsplash.com) backend.
  """

  alias Mobilizon.Service.HTTP.GenericJSONClient
  alias Mobilizon.Service.Pictures.{Information, Provider}
  require Logger

  @unsplash_api "/search/photos"
  @unsplash_name "Unsplash"

  @behaviour Provider

  @impl Provider
  @doc """
  Unsplash implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec search(String.t(), keyword()) :: Information.t()
  def search(location, _options \\ []) do
    url = "#{unsplash_endpoint()}#{@unsplash_api}?query=#{location}&orientation=landscape"

    client =
      GenericJSONClient.client(headers: [{:Authorization, "Client-ID #{unsplash_access_key()}"}])

    with {:ok, %{status: 200, body: body}} <- GenericJSONClient.get(client, url),
         results <- body["results"],
         {:empty, false} <- {:empty, Enum.empty?(results)},
         selected_picture <- Enum.random(results) do
      %Information{
        url: selected_picture["urls"]["small"],
        author: %{
          name: selected_picture["user"]["name"],
          url: "#{selected_picture["user"]["links"]["html"]}#{unsplash_utm_source()}"
        },
        source: %{
          name: @unsplash_name,
          url: unsplash_url()
        }
      }
    else
      {:empty, false} ->
        nil

      _ ->
        nil
    end
  end

  @impl Provider
  @doc """
  Returns the CSP configuration for this search provider to work
  """
  def csp do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:csp_policy, [])
  end

  defp unsplash_app_name do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:app_name])
  end

  defp unsplash_utm_source do
    "?utm_source=#{unsplash_app_name()}&utm_medium=referral"
  end

  defp unsplash_url do
    "https://unsplash.com/#{unsplash_utm_source()}"
  end

  defp unsplash_endpoint do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:endpoint]) ||
      "https://api.unsplash.com"
  end

  defp unsplash_access_key do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:access_key])
  end
end
