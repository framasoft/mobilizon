defmodule Mobilizon.GraphQL.API.Follows do
  @moduledoc """
  Common API for following, unfollowing, accepting and rejecting stuff.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}

  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}

  require Logger

  @doc """
  Make an actor (`follower`) follow another (`followed`).
  """
  @spec follow(follower :: Actor.t(), followed :: Actor.t()) ::
          {:ok, Activity.t(), Mobilizon.Actors.Follower.t()}
          | {:error, String.t()}
  def follow(%Actor{} = follower, %Actor{} = followed) do
    Actions.Follow.follow(follower, followed)
  end

  @doc """
  Make an actor (`follower`) unfollow another (`followed`).
  """
  @spec unfollow(follower :: Actor.t(), followed :: Actor.t()) ::
          {:ok, Activity.t(), Mobilizon.Actors.Follower.t()}
          | {:error, String.t()}
  def unfollow(%Actor{} = follower, %Actor{} = followed) do
    Actions.Follow.unfollow(follower, followed)
  end

  @doc """
  Make an actor (`followed`) accept the follow from another (`follower`).
  """
  @spec accept(follower :: Actor.t(), followed :: Actor.t()) ::
          {:ok, Activity.t(), Mobilizon.Actors.Follower.t()}
          | {:error, String.t()}
  def accept(%Actor{url: follower_url} = follower, %Actor{url: followed_url} = followed) do
    Logger.debug(
      "We're trying to accept a follow: #{followed_url} is accepting #{follower_url} follow request."
    )

    case Actors.is_following(follower, followed) do
      %Follower{approved: false} = follow ->
        Actions.Accept.accept(
          :follow,
          follow,
          true
        )

      %Follower{approved: true} ->
        {:error, "Follow already accepted"}

      nil ->
        {:error, "Can't accept follow: #{follower_url} is not following #{followed_url}."}
    end
  end

  @doc """
  Make an actor (`followed`) reject the follow from another (`follower`).
  """
  @spec reject(follower :: Actor.t(), followed :: Actor.t()) ::
          {:ok, Activity.t(), Mobilizon.Actors.Follower.t()}
          | {:error, String.t()}
  def reject(%Actor{url: follower_url} = follower, %Actor{url: followed_url} = followed) do
    Logger.debug(
      "We're trying to reject a follow: #{followed_url} is rejecting #{follower_url} follow request."
    )

    case Actors.is_following(follower, followed) do
      %Follower{approved: true} ->
        {:error, "Follow already accepted"}

      %Follower{} = follow ->
        Actions.Reject.reject(
          :follow,
          follow,
          true
        )

      nil ->
        {:error, "Follow not found"}
    end
  end
end
