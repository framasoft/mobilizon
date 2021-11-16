defmodule Mobilizon.Federation.ActivityPub.Actor do
  @moduledoc """
  Module to handle ActivityPub Actor interactions
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.{Fetcher, Relay}
  alias Mobilizon.Federation.WebFinger
  alias Mobilizon.Web.Endpoint
  require Logger
  import Mobilizon.Federation.ActivityPub.Utils, only: [are_same_origin?: 2]

  @doc """
  Getting an actor from url, eventually creating it if we don't have it locally or if it needs an update
  """
  @spec get_or_fetch_actor_by_url(url :: String.t(), preload :: boolean()) ::
          {:ok, Actor.t()}
          | {:error, make_actor_errors}
          | {:error, :no_internal_relay_actor}
          | {:error, :url_nil}
  def get_or_fetch_actor_by_url(url, preload \\ false)

  def get_or_fetch_actor_by_url(nil, _preload), do: {:error, :url_nil}

  def get_or_fetch_actor_by_url("https://www.w3.org/ns/activitystreams#Public", _preload) do
    %Actor{url: url} = Relay.get_actor()
    get_or_fetch_actor_by_url(url)
  end

  def get_or_fetch_actor_by_url(url, preload) do
    Logger.debug("Getting or fetching actor by URL #{url}")

    case Actors.get_actor_by_url(url, preload) do
      {:ok, %Actor{} = cached_actor} ->
        if Actors.needs_update?(cached_actor) do
          __MODULE__.make_actor_from_url(url, preload: preload)
        else
          {:ok, cached_actor}
        end

      {:error, :actor_not_found} ->
        # For tests, see https://github.com/jjh42/mock#not-supported---mocking-internal-function-calls and Mobilizon.Federation.ActivityPubTest
        __MODULE__.make_actor_from_url(url, preload: preload)
    end
  end

  @type make_actor_errors :: Fetcher.fetch_actor_errors() | :actor_is_local

  @doc """
  Create an actor locally by its URL (AP ID)
  """
  @spec make_actor_from_url(url :: String.t(), options :: Keyword.t()) ::
          {:ok, Actor.t()} | {:error, make_actor_errors | Ecto.Changeset.t()}
  def make_actor_from_url(url, options \\ []) do
    Logger.debug("Making actor from url #{url}")

    if are_same_origin?(url, Endpoint.url()) do
      {:error, :actor_is_local}
    else
      case Fetcher.fetch_and_prepare_actor_from_url(url, options) do
        {:ok, data} when is_map(data) ->
          Actors.upsert_actor(data, Keyword.get(options, :preload, false))

        # Request returned 410
        {:error, :actor_deleted} ->
          Logger.info("Actor #{url} was deleted")
          {:error, :actor_deleted}

        {:error, err} ->
          {:error, err}
      end
    end
  end

  @doc """
  Find an actor in our local database or call WebFinger to find what's its AP ID is and then fetch it
  """
  @spec find_or_make_actor_from_nickname(nickname :: String.t(), type :: atom() | nil) ::
          {:ok, Actor.t()} | {:error, make_actor_errors | WebFinger.finger_errors()}
  def find_or_make_actor_from_nickname(nickname, type \\ nil) do
    Logger.debug("Finding or making actor from nickname #{nickname}")

    case Actors.get_actor_by_name_with_preload(nickname, type) do
      %Actor{url: actor_url} = actor ->
        if Actors.needs_update?(actor) do
          make_actor_from_url(actor_url, preload: true)
        else
          {:ok, actor}
        end

      nil ->
        make_actor_from_nickname(nickname, preload: true)
    end
  end

  @spec find_or_make_group_from_nickname(nick :: String.t()) ::
          {:error, make_actor_errors | WebFinger.finger_errors()}
  def find_or_make_group_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Group)

  @doc """
  Create an actor inside our database from username, using WebFinger to find out its AP ID and then fetch it
  """
  @spec make_actor_from_nickname(nickname :: String.t(), preload :: boolean) ::
          {:ok, Actor.t()} | {:error, make_actor_errors | WebFinger.finger_errors()}
  def make_actor_from_nickname(nickname, preload \\ false) do
    Logger.debug("Fingering actor from nickname #{nickname}")

    case WebFinger.finger(nickname) do
      {:ok, url} when is_binary(url) ->
        Logger.debug("Matched #{nickname} to URL #{url}, now making actor")
        make_actor_from_url(url, preload: preload)

      {:error, e} ->
        {:error, e}
    end
  end
end
