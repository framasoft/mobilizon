# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub.ex

defmodule Mobilizon.Federation.ActivityPub do
  @moduledoc """
  The ActivityPub context.
  """

  import Mobilizon.Federation.ActivityPub.Utils

  alias Mobilizon.{
    Actors,
    Discussions,
    Events,
    Posts,
    Resources
  }

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Tombstone

  alias Mobilizon.Federation.ActivityPub.{
    Activity,
    Fetcher,
    Preloader,
    Relay
  }

  alias Mobilizon.Federation.ActivityStream.Convertible

  alias Mobilizon.Storage.Page

  alias Mobilizon.Web.Endpoint

  require Logger

  @public_ap_adress "https://www.w3.org/ns/activitystreams#Public"

  @doc """
  Fetch an object from an URL, from our local database of events and comments, then eventually remote
  """
  # TODO: Make database calls parallel
  @spec fetch_object_from_url(String.t(), Keyword.t()) ::
          {:ok, struct()} | {:ok, atom(), struct()} | {:error, any()}
  def fetch_object_from_url(url, options \\ []) do
    Logger.info("Fetching object from url #{url}")

    if String.starts_with?(url, "http") do
      with {:existing, nil} <-
             {:existing, Tombstone.find_tombstone(url)},
           {:existing, nil} <- {:existing, Events.get_event_by_url(url)},
           {:existing, nil} <-
             {:existing, Discussions.get_discussion_by_url(url)},
           {:existing, nil} <- {:existing, Discussions.get_comment_from_url(url)},
           {:existing, nil} <- {:existing, Resources.get_resource_by_url(url)},
           {:existing, nil} <- {:existing, Posts.get_post_by_url(url)},
           {:existing, nil} <-
             {:existing, Actors.get_actor_by_url_2(url)},
           {:existing, nil} <- {:existing, Actors.get_member_by_url(url)},
           :ok <- Logger.info("Data for URL not found anywhere, going to fetch it"),
           {:ok, _activity, entity} <- Fetcher.fetch_and_create(url, options) do
        Logger.debug("Going to preload the new entity")
        Preloader.maybe_preload(entity)
      else
        {:existing, entity} ->
          handle_existing_entity(url, entity, options)

        {:error, e} ->
          Logger.warn("Something failed while fetching url #{url} #{inspect(e)}")
          {:error, e}
      end
    else
      {:error, :url_not_http}
    end
  end

  @spec handle_existing_entity(String.t(), struct(), Keyword.t()) ::
          {:ok, struct()}
          | {:ok, atom(), struct()}
          | {:error, String.t(), struct()}
          | {:error, String.t()}
  defp handle_existing_entity(url, entity, options) do
    Logger.debug("Entity is already existing")
    Logger.debug("Going to preload an existing entity")

    case refresh_entity(url, entity, options) do
      {:ok, entity} ->
        Preloader.maybe_preload(entity)

      {:error, status, entity} ->
        {:ok, entity} = Preloader.maybe_preload(entity)
        {:error, status, entity}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec refresh_entity(String.t(), struct(), Keyword.t()) ::
          {:ok, struct()} | {:error, atom(), struct()} | {:error, atom()}
  defp refresh_entity(url, entity, options) do
    force_fetch = Keyword.get(options, :force, false)

    if force_fetch and not are_same_origin?(url, Endpoint.url()) do
      Logger.debug("Entity is external and we want a force fetch")

      case Fetcher.fetch_and_update(url, options) do
        {:ok, _activity, entity} ->
          {:ok, entity}

        {:error, :http_gone} ->
          {:error, :http_gone, entity}

        {:error, :http_not_found} ->
          {:error, :http_not_found, entity}

        {:error, err} ->
          {:error, err}
      end
    else
      {:ok, entity}
    end
  end

  @doc """
  Return all public activities (events & comments) for an actor
  """
  @spec fetch_public_activities_for_actor(Actor.t(), pos_integer(), pos_integer()) :: map()
  def fetch_public_activities_for_actor(%Actor{id: actor_id} = actor, page \\ 1, limit \\ 10) do
    %Actor{id: relay_actor_id} = Relay.get_actor()

    %Page{total: total_events, elements: events} =
      if actor_id == relay_actor_id do
        Events.list_public_local_events(page, limit)
      else
        Events.list_public_events_for_actor(actor, page, limit)
      end

    %Page{total: total_comments, elements: comments} =
      if actor_id == relay_actor_id do
        Discussions.list_local_comments(page, limit)
      else
        Discussions.list_public_comments_for_actor(actor, page, limit)
      end

    event_activities = Enum.map(events, &event_to_activity/1)
    comment_activities = Enum.map(comments, &comment_to_activity/1)
    activities = event_activities ++ comment_activities

    %{elements: activities, total: total_events + total_comments}
  end

  # Create an activity from an event
  @spec event_to_activity(%Event{}, boolean()) :: Activity.t()
  defp event_to_activity(%Event{} = event, local \\ true) do
    %Activity{
      recipients: [@public_ap_adress],
      actor: event.organizer_actor.url,
      data: event |> Convertible.model_to_as() |> make_create_data(%{"to" => @public_ap_adress}),
      local: local
    }
  end

  # Create an activity from a comment
  @spec comment_to_activity(%Comment{}, boolean()) :: Activity.t()
  defp comment_to_activity(%Comment{} = comment, local \\ true) do
    %Activity{
      recipients: [@public_ap_adress],
      actor: comment.actor.url,
      data:
        comment |> Convertible.model_to_as() |> make_create_data(%{"to" => @public_ap_adress}),
      local: local
    }
  end
end
