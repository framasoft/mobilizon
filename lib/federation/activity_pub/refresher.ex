defmodule Mobilizon.Federation.ActivityPub.Refresher do
  @moduledoc """
  Module that provides functions to explore and fetch collections on a group
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityStream.Converter.Member, as: MemberConverter
  alias Mobilizon.Federation.ActivityStream.Converter.Resource, as: ResourceConverter
  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Resources
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [maybe_date_fetch: 2, sign_fetch: 4]

  @spec fetch_group(String.t(), Actor.t()) :: :ok
  def fetch_group(group_url, %Actor{} = on_behalf_of) do
    with {:ok, %Actor{resources_url: resources_url, members_url: members_url}} <-
           ActivityPub.get_or_fetch_actor_by_url(group_url) do
      fetch_collection(members_url, on_behalf_of)
      fetch_collection(resources_url, on_behalf_of)
    end
  end

  def fetch_collection(nil, _on_behalf_of), do: :error

  def fetch_collection(collection_url, on_behalf_of) do
    Logger.debug("Fetching and preparing collection from url")
    Logger.debug(inspect(collection_url))

    with {:ok, data} <- fetch(collection_url, on_behalf_of) do
      Logger.debug("Fetch ok, passing to process_collection")
      process_collection(data, on_behalf_of)
    end
  end

  defp process_collection(%{"type" => type, "orderedItems" => items}, _on_behalf_of)
       when type in ["OrderedCollection", "OrderedCollectionPage"] do
    Logger.debug(
      "Processing an OrderedCollection / OrderedCollectionPage with has direct orderedItems"
    )

    Logger.debug(inspect(items))

    Enum.each(items, &handling_element/1)
  end

  defp process_collection(%{"type" => "OrderedCollection", "first" => first}, on_behalf_of)
       when is_map(first),
       do: process_collection(first, on_behalf_of)

  defp process_collection(%{"type" => "OrderedCollection", "first" => first}, on_behalf_of)
       when is_bitstring(first) do
    Logger.debug("OrderedCollection has a first property pointing to an URI")

    with {:ok, data} <- fetch(first, on_behalf_of) do
      Logger.debug("Fetched the collection for first property")
      process_collection(data, on_behalf_of)
    end
  end

  defp handling_element(%{"type" => "Member"} = data) do
    Logger.debug("Handling Member element")

    data
    |> MemberConverter.as_to_model_data()
    |> Actors.create_member()
  end

  defp handling_element(%{"type" => type} = data)
       when type in ["Document", "ResourceCollection"] do
    Logger.debug("Handling Resource element")

    data
    |> ResourceConverter.as_to_model_data()
    |> Resources.create_resource()
  end

  defp fetch(url, %Actor{} = on_behalf_of) do
    with date <- Signature.generate_date_header(),
         headers <-
           [{:Accept, "application/activity+json"}]
           |> maybe_date_fetch(date)
           |> sign_fetch(on_behalf_of, url, date),
         %HTTPoison.Response{status_code: 200, body: body} <-
           HTTPoison.get!(url, headers,
             follow_redirect: true,
             ssl: [{:versions, [:"tlsv1.2"]}]
           ),
         {:ok, data} <-
           Jason.decode(body) do
      {:ok, data}
    else
      # Actor is gone, probably deleted
      {:ok, %HTTPoison.Response{status_code: 410}} ->
        Logger.info("Response HTTP 410")
        {:error, :actor_deleted}

      {:origin_check, false} ->
        {:error, "Origin check failed"}

      e ->
        Logger.warn("Could not decode actor at fetch #{url}, #{inspect(e)}")
        {:error, e}
    end
  end
end
