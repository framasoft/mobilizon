defmodule Mobilizon.GraphQL.API.Follows do
  @moduledoc """
  Common API for following, unfollowing, accepting and rejecting stuff.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity

  require Logger

  def follow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.follow(follower, followed) do
      {:ok, activity, follow} ->
        {:ok, activity, follow}

      {:error, e} ->
        Logger.warn("Error while following actor: #{inspect(e)}")
        {:error, e}

      e ->
        Logger.warn("Error while following actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def unfollow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.unfollow(follower, followed) do
      {:ok, activity, follow} ->
        {:ok, activity, follow}

      e ->
        Logger.warn("Error while unfollowing actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def accept(%Actor{} = follower, %Actor{} = followed) do
    Logger.debug("We're trying to accept a follow")

    with %Follower{approved: false} = follow <-
           Actors.is_following(follower, followed),
         {:ok, %Activity{} = activity, %Follower{approved: true} = follow} <-
           ActivityPub.accept(
             :follow,
             follow,
             true
           ) do
      {:ok, activity, follow}
    else
      %Follower{approved: true} ->
        {:error, "Follow already accepted"}
    end
  end

  def reject(%Actor{} = follower, %Actor{} = followed) do
    Logger.debug("We're trying to reject a follow")

    with {:follower, %Follower{} = follow} <-
           {:follower, Actors.is_following(follower, followed)},
         {:ok, %Activity{} = activity, %Follower{} = follow} <-
           ActivityPub.reject(
             :follow,
             follow,
             true
           ) do
      {:ok, activity, follow}
    else
      {:follower, nil} ->
        {:error, "Follow not found"}

      {:follower, %Follower{approved: true}} ->
        {:error, "Follow already accepted"}
    end
  end
end
