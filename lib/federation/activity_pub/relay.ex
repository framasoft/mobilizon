# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/relay.ex

defmodule Mobilizon.Federation.ActivityPub.Relay do
  @moduledoc """
  Handles following and unfollowing relays and instances.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Refresher, Transmogrifier}
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.WebFinger

  alias Mobilizon.GraphQL.API.Follows

  require Logger

  def init do
    # Wait for everything to settle.
    Process.sleep(1000 * 5)
    get_actor()
  end

  @spec get_actor() :: Actor.t() | {:error, Ecto.Changeset.t()}
  def get_actor do
    with {:ok, %Actor{} = actor} <-
           Actors.get_or_create_internal_actor("relay") do
      actor
    end
  end

  @spec follow(String.t()) :: {:ok, Activity.t(), Follower.t()}
  def follow(address) do
    with {:ok, target_instance} <- fetch_actor(address),
         %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(target_instance),
         {:ok, activity, follow} <- Follows.follow(local_actor, target_actor) do
      Logger.info("Relay: followed instance #{target_instance}; id=#{activity.data["id"]}")
      {:ok, activity, follow}
    else
      {:error, e} ->
        Logger.warn("Error while following remote instance: #{inspect(e)}")
        {:error, e}

      e ->
        Logger.warn("Error while following remote instance: #{inspect(e)}")
        {:error, e}
    end
  end

  @spec unfollow(String.t()) :: {:ok, Activity.t(), Follower.t()}
  def unfollow(address) do
    with {:ok, target_instance} <- fetch_actor(address),
         %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(target_instance),
         {:ok, activity, follow} <- Follows.unfollow(local_actor, target_actor) do
      Logger.info("Relay: unfollowed instance #{target_instance}: id=#{activity.data["id"]}")
      {:ok, activity, follow}
    else
      e ->
        Logger.warn("Error while unfollowing remote instance: #{inspect(e)}")
        {:error, e}
    end
  end

  @spec accept(String.t()) :: {:ok, Activity.t(), Follower.t()}
  def accept(address) do
    Logger.debug("We're trying to accept a relay subscription")

    with {:ok, target_instance} <- fetch_actor(address),
         %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(target_instance),
         {:ok, activity, follow} <- Follows.accept(target_actor, local_actor) do
      {:ok, activity, follow}
    end
  end

  def reject(address) do
    Logger.debug("We're trying to reject a relay subscription")

    with {:ok, target_instance} <- fetch_actor(address),
         %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(target_instance),
         {:ok, activity, follow} <- Follows.reject(target_actor, local_actor) do
      {:ok, activity, follow}
    end
  end

  def refresh(address) do
    Logger.debug("We're trying to refresh a remote instance")

    with {:ok, target_instance} <- fetch_actor(address),
         {:ok, %Actor{} = target_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(target_instance) do
      Refresher.refresh_profile(target_actor)
    end
  end

  @doc """
  Publish an activity to all relays following this instance
  """
  def publish(%Activity{data: %{"object" => object}} = _activity) do
    with %Actor{id: actor_id} = actor <- get_actor(),
         {object, object_id} <- fetch_object(object),
         id <- "#{object_id}/announces/#{actor_id}" do
      Logger.info("Publishing activity #{id} to all relays")
      ActivityPub.announce(actor, object, id, true, false)
    else
      e ->
        Logger.error("Error while getting local instance actor: #{inspect(e)}")
    end
  end

  def publish(err) do
    Logger.error("Tried to publish a bad activity")
    Logger.debug(inspect(err))
    nil
  end

  defp fetch_object(object) when is_map(object) do
    with {:ok, object} <- Transmogrifier.fetch_obj_helper_as_activity_streams(object) do
      {object, object["id"]}
    end
  end

  defp fetch_object(object) when is_binary(object), do: {object, object}

  @spec fetch_actor(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  # Dirty hack
  defp fetch_actor("https://" <> address), do: fetch_actor(address)
  defp fetch_actor("http://" <> address), do: fetch_actor(address)

  defp fetch_actor(address) do
    %URI{host: host} = URI.parse("http://" <> address)

    cond do
      String.contains?(address, "@") ->
        check_actor(address)

      !is_nil(host) ->
        check_actor("relay@#{host}")

      true ->
        {:error, "Bad URL"}
    end
  end

  @spec check_actor(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp check_actor(username_and_domain) do
    case Actors.get_actor_by_name(username_and_domain) do
      %Actor{url: url} -> {:ok, url}
      nil -> finger_actor(username_and_domain)
    end
  end

  @spec finger_actor(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp finger_actor(nickname) do
    case WebFinger.finger(nickname) do
      {:ok, url} when is_binary(url) ->
        {:ok, url}

      _e ->
        {:error, "No ActivityPub URL found in WebFinger"}
    end
  end
end
