defmodule Mobilizon.Service.Pictures.Provider do
  @moduledoc """
  Provider Behaviour for pictures stuff.

  ## Supported backends

    * `Mobilizon.Service.Pictures.Unsplash` [🔗](https://unsplash.com/developers)
    * `Mobilizon.Service.Pictures.Flickr` [🔗](https://www.flickr.com/services/api/)

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

  alias Mobilizon.Service.Pictures.Information

  @doc """
  Get a picture for a location

  ## Examples

      iex> search("London")
      %Information{url: "https://some_url_to.a/picture.jpeg", author: %{name: "An author", url: "https://url.to/profile"}, source: %{name: "The source name", url: "The source URL" }}
  """
  @callback search(location :: String.t(), options :: keyword) :: Information.t()

  @doc """
  The CSP configuration to add for the service to work
  """
  @callback csp() :: keyword()

  @spec endpoint(atom()) :: String.t()
  def endpoint(provider) do
    Application.get_env(:mobilizon, provider) |> get_in([:endpoint])
  end
end
