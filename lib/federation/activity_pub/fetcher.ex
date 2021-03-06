defmodule Mobilizon.Federation.ActivityPub.Fetcher do
  @moduledoc """
  Module to handle direct URL ActivityPub fetches to remote content

  If you need to first get cached data, see `Mobilizon.Federation.ActivityPub.fetch_object_from_url/2`
  """
  require Logger

  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Federation.ActivityPub.{Relay, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Converter.Actor, as: ActorConverter
  alias Mobilizon.Service.ErrorReporting.Sentry
  alias Mobilizon.Service.HTTP.ActivityPub, as: ActivityPubClient

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [maybe_date_fetch: 2, sign_fetch: 4, origin_check?: 2]

  @spec fetch(String.t(), Keyword.t()) :: {:ok, map()}
  def fetch(url, options \\ []) do
    on_behalf_of = Keyword.get(options, :on_behalf_of, Relay.get_actor())

    with false <- address_invalid(url),
         date <- Signature.generate_date_header(),
         headers <-
           [{:Accept, "application/activity+json"}]
           |> maybe_date_fetch(date)
           |> sign_fetch(on_behalf_of, url, date),
         client <-
           ActivityPubClient.client(headers: headers),
         {:ok, %Tesla.Env{body: data, status: code}} when code in 200..299 <-
           ActivityPubClient.get(client, url) do
      {:ok, data}
    else
      {:ok, %Tesla.Env{status: 410}} ->
        Logger.debug("Resource at #{url} is 410 Gone")
        {:error, "Gone"}

      {:ok, %Tesla.Env{status: 404}} ->
        Logger.debug("Resource at #{url} is 404 Gone")
        {:error, "Not found"}

      {:ok, %Tesla.Env{} = res} ->
        {:error, res}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_and_create(String.t(), Keyword.t()) :: {:ok, map(), struct()}
  def fetch_and_create(url, options \\ []) do
    with {:ok, data} when is_map(data) <- fetch(url, options),
         {:origin_check, true} <- {:origin_check, origin_check?(url, data)},
         params <- %{
           "type" => "Create",
           "to" => data["to"],
           "cc" => data["cc"],
           "actor" => data["actor"] || data["attributedTo"],
           "attributedTo" => data["attributedTo"] || data["actor"],
           "object" => data
         } do
      Transmogrifier.handle_incoming(params)
    else
      {:origin_check, false} ->
        Logger.warn("Object origin check failed")
        {:error, "Object origin check failed"}

      # Returned content is not JSON
      {:ok, data} when is_binary(data) ->
        {:error, "Failed to parse content as JSON"}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_and_update(String.t(), Keyword.t()) :: {:ok, map(), struct()}
  def fetch_and_update(url, options \\ []) do
    with {:ok, data} when is_map(data) <- fetch(url, options),
         {:origin_check, true} <- {:origin_check, origin_check(url, data)},
         params <- %{
           "type" => "Update",
           "to" => data["to"],
           "cc" => data["cc"],
           "actor" => data["actor"] || data["attributedTo"],
           "attributedTo" => data["attributedTo"] || data["actor"],
           "object" => data
         } do
      Transmogrifier.handle_incoming(params)
    else
      {:origin_check, false} ->
        {:error, "Object origin check failed"}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Fetching a remote actor's information through its AP ID
  """
  @spec fetch_and_prepare_actor_from_url(String.t()) :: {:ok, map()} | {:error, atom()} | any()
  def fetch_and_prepare_actor_from_url(url) do
    Logger.debug("Fetching and preparing actor from url")
    Logger.debug(inspect(url))

    res =
      with {:ok, %{status: 200, body: body}} <-
             Tesla.get(url,
               headers: [{"Accept", "application/activity+json"}],
               follow_redirect: true
             ),
           :ok <- Logger.debug("response okay, now decoding json"),
           {:ok, data} <- Jason.decode(body) do
        Logger.debug("Got activity+json response at actor's endpoint, now converting data")
        {:ok, ActorConverter.as_to_model_data(data)}
      else
        # Actor is gone, probably deleted
        {:ok, %{status: 410}} ->
          Logger.info("Response HTTP 410")
          {:error, :actor_deleted}

        {:ok, %Tesla.Env{}} ->
          Logger.info("Non 200 HTTP Code")
          {:error, :http_error}

        {:error, e} ->
          Logger.warn("Could not decode actor at fetch #{url}, #{inspect(e)}")
          {:error, e}

        e ->
          Logger.warn("Could not decode actor at fetch #{url}, #{inspect(e)}")
          {:error, e}
      end

    res
  end

  @spec origin_check(String.t(), map()) :: boolean()
  defp origin_check(url, data) do
    if origin_check?(url, data) do
      true
    else
      Sentry.capture_message("Object origin check failed", extra: %{url: url, data: data})
      Logger.debug("Object origin check failed")
      false
    end
  end

  @spec address_invalid(String.t()) :: false | {:error, :invalid_url}
  defp address_invalid(address) do
    with %URI{host: host, scheme: scheme} <- URI.parse(address),
         true <- is_nil(host) or is_nil(scheme) do
      {:error, :invalid_url}
    end
  end
end
