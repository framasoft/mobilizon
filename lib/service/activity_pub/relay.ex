# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/relay.ex

defmodule Mobilizon.Service.ActivityPub.Relay do
  @moduledoc """
  Handles following and unfollowing relays and instances
  """

  alias Mobilizon.Activity
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias MobilizonWeb.API.Follows
  require Logger

  def get_actor do
    with {:ok, %Actor{} = actor} <-
           Actors.get_or_create_service_actor_by_url("#{MobilizonWeb.Endpoint.url()}/relay") do
      actor
    end
  end

  def follow(target_instance) do
    with %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <- Actors.get_or_fetch_by_url(target_instance),
         {:ok, activity} <- Follows.follow(local_actor, target_actor) do
      Logger.info("Relay: followed instance #{target_instance}; id=#{activity.data["id"]}")
      {:ok, activity}
    else
      e ->
        Logger.warn("Error while following remote instance: #{inspect(e)}")
        {:error, e}
    end
  end

  def unfollow(target_instance) do
    with %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <- Actors.get_or_fetch_by_url(target_instance),
         {:ok, activity} <- Follows.unfollow(local_actor, target_actor) do
      Logger.info("Relay: unfollowed instance #{target_instance}: id=#{activity.data["id"]}")
      {:ok, activity}
    else
      e ->
        Logger.warn("Error while unfollowing remote instance: #{inspect(e)}")
        {:error, e}
    end
  end

  def accept(target_instance) do
    with %Actor{} = local_actor <- get_actor(),
         {:ok, %Actor{} = target_actor} <- Actors.get_or_fetch_by_url(target_instance),
         {:ok, activity} <- Follows.accept(target_actor, local_actor) do
      {:ok, activity}
    end
  end

  #  def reject(target_instance) do
  #    with %Actor{} = local_actor <- get_actor(),
  #         {:ok, %Actor{} = target_actor} <- Actors.get_or_fetch_by_url(target_instance),
  #         {:ok, activity} <- Follows.reject(target_actor, local_actor) do
  #      {:ok, activity}
  #    end
  #  end

  @doc """
  Publish an activity to all relays following this instance
  """
  def publish(%Activity{data: %{"object" => object}} = _activity) do
    with %Actor{id: actor_id} = actor <- get_actor(),
         {:ok, object} <-
           Mobilizon.Service.ActivityPub.Transmogrifier.fetch_obj_helper_as_activity_streams(
             object
           ) do
      ActivityPub.announce(actor, object, "#{object["id"]}/announces/#{actor_id}", true, false)
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
end
