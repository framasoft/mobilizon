defmodule Mobilizon.Federation.ActivityPub.Fetcher do
  @moduledoc """
  Module to handle direct URL ActivityPub fetches to remote content

  If you need to first get cached data, see `Mobilizon.Federation.ActivityPub.fetch_object_from_url/2`
  """
  require Logger

  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Federation.ActivityPub.{Relay, Transmogrifier}
  alias Mobilizon.Service.HTTP.ActivityPub, as: ActivityPubClient

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [maybe_date_fetch: 2, sign_fetch: 4, origin_check?: 2]

  @spec fetch(String.t(), Keyword.t()) :: {:ok, map()}
  def fetch(url, options \\ []) do
    on_behalf_of = Keyword.get(options, :on_behalf_of, Relay.get_actor())

    with date <- Signature.generate_date_header(),
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
        Logger.warn("Resource at #{url} is 410 Gone")
        {:error, "Gone"}

      {:ok, %Tesla.Env{status: 404}} ->
        Logger.warn("Resource at #{url} is 404 Gone")
        {:error, "Not found"}

      {:ok, %Tesla.Env{} = res} ->
        {:error, res}
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

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_and_update(String.t(), Keyword.t()) :: {:ok, map(), struct()}
  def fetch_and_update(url, options \\ []) do
    with {:ok, data} when is_map(data) <- fetch(url, options),
         {:origin_check, true} <- {:origin_check, origin_check?(url, data)},
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
        Logger.warn("Object origin check failed")
        {:error, "Object origin check failed"}

      {:error, err} ->
        {:error, err}
    end
  end
end
