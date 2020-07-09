defmodule Mobilizon.Federation.ActivityPub.Refresher do
  @moduledoc """
  Module that provides functions to explore and fetch collections on a group
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Fetcher, Transmogrifier}
  require Logger

  @spec fetch_group(String.t(), Actor.t()) :: :ok
  def fetch_group(group_url, %Actor{} = on_behalf_of) do
    with {:ok,
          %Actor{
            outbox_url: outbox_url,
            resources_url: resources_url,
            members_url: members_url,
            posts_url: posts_url,
            todos_url: todos_url,
            discussions_url: discussions_url,
            events_url: events_url
          }} <-
           ActivityPub.get_or_fetch_actor_by_url(group_url) do
      fetch_collection(outbox_url, on_behalf_of)
      fetch_collection(members_url, on_behalf_of)
      fetch_collection(resources_url, on_behalf_of)
      fetch_collection(posts_url, on_behalf_of)
      fetch_collection(todos_url, on_behalf_of)
      fetch_collection(discussions_url, on_behalf_of)
      fetch_collection(events_url, on_behalf_of)
    end
  end

  def fetch_collection(nil, _on_behalf_of), do: :error

  def fetch_collection(collection_url, on_behalf_of) do
    Logger.debug("Fetching and preparing collection from url")
    Logger.debug(inspect(collection_url))

    with {:ok, data} <- Fetcher.fetch(collection_url, on_behalf_of: on_behalf_of) do
      Logger.debug("Fetch ok, passing to process_collection")
      process_collection(data, on_behalf_of)
    end
  end

  @spec fetch_element(String.t(), Actor.t()) :: any()
  def fetch_element(url, %Actor{} = on_behalf_of) do
    with {:ok, data} <- Fetcher.fetch(url, on_behalf_of: on_behalf_of) do
      case handling_element(data) do
        {:ok, _activity, entity} ->
          {:ok, entity}

        {:ok, entity} ->
          {:ok, entity}

        err ->
          {:error, err}
      end
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

    with {:ok, data} <- Fetcher.fetch(first, on_behalf_of: on_behalf_of) do
      Logger.debug("Fetched the collection for first property")
      process_collection(data, on_behalf_of)
    end
  end

  defp handling_element(data) when is_map(data) do
    activity = %{
      "type" => "Create",
      "to" => data["to"],
      "cc" => data["cc"],
      "actor" => data["actor"],
      "attributedTo" => data["attributedTo"],
      "object" => data
    }

    Transmogrifier.handle_incoming(activity)
  end

  defp handling_element(uri) when is_binary(uri) do
    ActivityPub.fetch_object_from_url(uri)
  end
end
