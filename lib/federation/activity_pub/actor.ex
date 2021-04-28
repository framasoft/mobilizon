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
  @spec get_or_fetch_actor_by_url(String.t(), boolean) :: {:ok, Actor.t()} | {:error, String.t()}
  def get_or_fetch_actor_by_url(url, preload \\ false)

  def get_or_fetch_actor_by_url(nil, _preload), do: {:error, "Can't fetch a nil url"}

  def get_or_fetch_actor_by_url("https://www.w3.org/ns/activitystreams#Public", _preload) do
    with %Actor{url: url} <- Relay.get_actor() do
      get_or_fetch_actor_by_url(url)
    end
  end

  @spec get_or_fetch_actor_by_url(String.t(), boolean()) :: {:ok, Actor.t()} | {:error, any()}
  def get_or_fetch_actor_by_url(url, preload) do
    with {:ok, %Actor{} = cached_actor} <- Actors.get_actor_by_url(url, preload),
         false <- Actors.needs_update?(cached_actor) do
      {:ok, cached_actor}
    else
      _ ->
        # For tests, see https://github.com/jjh42/mock#not-supported---mocking-internal-function-calls and Mobilizon.Federation.ActivityPubTest
        case __MODULE__.make_actor_from_url(url, preload) do
          {:ok, %Actor{} = actor} ->
            {:ok, actor}

          {:error, err} ->
            Logger.debug("Could not fetch by AP id")
            Logger.debug(inspect(err))
            {:error, "Could not fetch by AP id"}
        end
    end
  end

  @doc """
  Create an actor locally by its URL (AP ID)
  """
  @spec make_actor_from_url(String.t(), boolean()) ::
          {:ok, %Actor{}} | {:error, :actor_deleted} | {:error, :http_error} | {:error, any()}
  def make_actor_from_url(url, preload \\ false) do
    if are_same_origin?(url, Endpoint.url()) do
      {:error, "Can't make a local actor from URL"}
    else
      case Fetcher.fetch_and_prepare_actor_from_url(url) do
        {:ok, data} ->
          Actors.upsert_actor(data, preload)

        # Request returned 410
        {:error, :actor_deleted} ->
          Logger.info("Actor was deleted")
          {:error, :actor_deleted}

        {:error, :http_error} ->
          {:error, :http_error}

        {:error, e} ->
          Logger.warn("Failed to make actor from url")
          {:error, e}
      end
    end
  end

  @doc """
  Find an actor in our local database or call WebFinger to find what's its AP ID is and then fetch it
  """
  @spec find_or_make_actor_from_nickname(String.t(), atom() | nil) :: tuple()
  def find_or_make_actor_from_nickname(nickname, type \\ nil) do
    case Actors.get_actor_by_name(nickname, type) do
      %Actor{} = actor ->
        {:ok, actor}

      nil ->
        make_actor_from_nickname(nickname)
    end
  end

  @spec find_or_make_group_from_nickname(String.t()) :: tuple()
  def find_or_make_group_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Group)

  @doc """
  Create an actor inside our database from username, using WebFinger to find out its AP ID and then fetch it
  """
  @spec make_actor_from_nickname(String.t()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_nickname(nickname) do
    case WebFinger.finger(nickname) do
      {:ok, url} when is_binary(url) ->
        make_actor_from_url(url)

      _e ->
        {:error, "No ActivityPub URL found in WebFinger"}
    end
  end
end
