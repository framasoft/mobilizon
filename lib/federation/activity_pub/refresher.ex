defmodule Mobilizon.Federation.ActivityPub.Refresher do
  @moduledoc """
  Module that provides functions to explore and fetch collections on a group
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.{Fetcher, Relay, Transmogrifier, Utils}
  require Logger

  @doc """
  Refresh a remote profile
  """
  @spec refresh_profile(Actor.t()) :: {:ok, Actor.t()} | {:error, fetch_actor_errors()} | {:error}
  def refresh_profile(%Actor{domain: nil}), do: {:error, "Can only refresh remote actors"}

  def refresh_profile(%Actor{type: :Group, url: url, id: group_id} = group) do
    on_behalf_of =
      case Actors.get_single_group_member_actor(group_id) do
        %Actor{} = member_actor ->
          member_actor

        _ ->
          Relay.get_actor()
      end

    with :ok <- fetch_group(url, on_behalf_of) do
      {:ok, group}
    end
  end

  def refresh_profile(%Actor{type: type, url: url}) when type in [:Person, :Application] do
    case ActivityPubActor.make_actor_from_url(url) do
      {:ok, %Actor{outbox_url: outbox_url} = actor} ->
        case fetch_collection(outbox_url, Relay.get_actor()) do
          :ok -> {:ok, actor}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @type fetch_actor_errors :: ActivityPubActor.make_actor_errors() | fetch_collection_errors()

  @spec fetch_group(String.t(), Actor.t()) :: :ok | {:error, fetch_actor_errors}
  def fetch_group(group_url, %Actor{} = on_behalf_of) do
    case ActivityPubActor.make_actor_from_url(group_url) do
      {:ok,
       %Actor{
         outbox_url: outbox_url,
         resources_url: resources_url,
         members_url: members_url,
         posts_url: posts_url,
         todos_url: todos_url,
         discussions_url: discussions_url,
         events_url: events_url
       }} ->
        Logger.debug("Fetched group OK, now doing collections")

        with :ok <- fetch_collection(outbox_url, on_behalf_of),
             :ok <- fetch_collection(members_url, on_behalf_of),
             :ok <- fetch_collection(resources_url, on_behalf_of),
             :ok <- fetch_collection(posts_url, on_behalf_of),
             :ok <- fetch_collection(todos_url, on_behalf_of),
             :ok <- fetch_collection(discussions_url, on_behalf_of),
             :ok <- fetch_collection(events_url, on_behalf_of) do
          :ok
        else
          {:error, err}
          when err in [:error, :process_error, :fetch_error, :collection_url_nil] ->
            Logger.debug("Error while fetching actor collection")
            {:error, err}
        end

      {:error, err}
      when err in [:actor_deleted, :http_error, :json_decode_error, :actor_is_local] ->
        Logger.debug("Error while making actor")
        {:error, err}
    end
  end

  @typep fetch_collection_errors :: :process_error | :fetch_error | :collection_url_nil

  @spec fetch_collection(String.t() | nil, any) ::
          :ok | {:error, fetch_collection_errors}
  def fetch_collection(nil, _on_behalf_of), do: {:error, :collection_url_nil}

  def fetch_collection(collection_url, on_behalf_of) do
    Logger.debug("Fetching and preparing collection from url")
    Logger.debug(inspect(collection_url))

    case Fetcher.fetch(collection_url, on_behalf_of: on_behalf_of) do
      {:ok, data} when is_map(data) ->
        Logger.debug("Fetch ok, passing to process_collection")

        case process_collection(data, on_behalf_of) do
          :ok ->
            Logger.debug("Finished processing a collection")
            :ok

          :error ->
            Logger.debug("Failed to process collection #{collection_url}")
            {:error, :process_error}
        end

      {:error, _err} ->
        Logger.debug("Failed to fetch collection #{collection_url}")
        {:error, :fetch_error}
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

  @spec refresh_all_external_groups :: :ok
  def refresh_all_external_groups do
    Actors.list_external_groups()
    |> Enum.filter(&Actors.needs_update?/1)
    |> Enum.each(&refresh_profile/1)
  end

  @spec process_collection(map(), any()) :: :ok | :error
  defp process_collection(%{"type" => type, "orderedItems" => items}, _on_behalf_of)
       when type in ["OrderedCollection", "OrderedCollectionPage"] do
    Logger.debug(
      "Processing an OrderedCollection / OrderedCollectionPage with has direct orderedItems"
    )

    Logger.debug(inspect(items))

    items
    |> Enum.map(fn item -> Task.async(fn -> handling_element(item) end) end)
    |> Task.await_many()

    Logger.debug("Finished processing a collection")
    :ok
  end

  # Lemmy uses an OrderedCollection with the items property
  defp process_collection(%{"type" => type, "items" => items} = collection, on_behalf_of)
       when type in ["OrderedCollection", "OrderedCollectionPage"] do
    collection
    |> Map.put("orderedItems", items)
    |> process_collection(on_behalf_of)
  end

  defp process_collection(%{"type" => "OrderedCollection", "first" => first}, on_behalf_of)
       when is_map(first),
       do: process_collection(first, on_behalf_of)

  defp process_collection(%{"type" => "OrderedCollection", "first" => first}, on_behalf_of)
       when is_binary(first) do
    Logger.debug("OrderedCollection has a first property pointing to an URI")

    with {:ok, data} <- Fetcher.fetch(first, on_behalf_of: on_behalf_of) do
      Logger.debug("Fetched the collection for first property")
      process_collection(data, on_behalf_of)
    end
  end

  defp process_collection(_, _), do: :error

  # If we're handling an activity
  @spec handling_element(map()) :: {:ok, any, struct} | :error
  @spec handling_element(String.t()) :: {:ok, struct} | {:error, any()}
  defp handling_element(%{"type" => activity_type} = data)
       when activity_type in ["Create", "Update", "Delete"] do
    object = get_in(data, ["object"])

    if object do
      object |> Utils.get_url() |> Mobilizon.Tombstone.delete_uri_tombstone()
    end

    Transmogrifier.handle_incoming(data)
  end

  # If we're handling an announce activity
  defp handling_element(%{"type" => "Announce"} = data) do
    handling_element(get_in(data, ["object"]))
  end

  # If we're handling directly an object
  defp handling_element(data) when is_map(data) do
    object = get_in(data, ["object"])

    if object do
      object |> Utils.get_url() |> Mobilizon.Tombstone.delete_uri_tombstone()
    end

    activity = %{
      "type" => "Create",
      "to" => data["to"],
      "cc" => data["cc"],
      "actor" => data["actor"] || data["attributedTo"],
      "attributedTo" => data["attributedTo"] || data["actor"],
      "object" => data
    }

    Transmogrifier.handle_incoming(activity)
  end

  defp handling_element(uri) when is_binary(uri) do
    ActivityPub.fetch_object_from_url(uri)
  end
end
