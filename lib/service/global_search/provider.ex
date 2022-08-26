defmodule Mobilizon.Service.GlobalSearch.Provider do
  @moduledoc """
  Provider Behaviour for Global Search.

  ## Supported backends

    * `Mobilizon.Service.GlobalSearch.Mobilizon` [🔗](https://framagit.org/framasoft/joinmobilizon/search-index/)

  ## Shared options

    * `:lang` Lang in which to prefer results. Used as a request parameter or
      through an `Accept-Language` HTTP header. Defaults to `"en"`.
    * `:country_code` An ISO 3166 country code. String or `nil`
    * `:limit` Maximum limit for the number of results returned by the backend.
      Defaults to `10`
    * `:api_key` Allows to override the API key (if the backend requires one) set
      inside the configuration.
    * `:endpoint` Allows to override the endpoint set inside the configuration.
  """

  alias Mobilizon.Service.GlobalSearch.{EventResult, GroupResult}

  @doc """
  Get global search results for a search string

  ## Examples

      iex> search_events(search: "London")
      [%EventResult{id: "provider-534", origin_url: "https://somewhere.else", title: "MyEvent", begins_on: "2022-08-25T08:13:47+0200", ends_on: "2022-08-25T10:13:47+0200", category: "FILM_MEDIA", tags: ["something", "what"], participants: 5}]
  """
  @callback search_events(search_options :: keyword) ::
              Page.t(EventResult.t())
  @callback search_groups(search_options :: keyword) ::
              Page.t(GroupResult.t())

  @spec endpoint(atom()) :: String.t()
  def endpoint(provider) do
    Application.get_env(:mobilizon, provider) |> get_in([:endpoint])
  end
end
