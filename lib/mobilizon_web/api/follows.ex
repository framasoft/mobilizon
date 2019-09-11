defmodule MobilizonWeb.API.Follows do
  @moduledoc """
  Common API for following, unfollowing, accepting and rejecting stuff.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Service.ActivityPub
  require Logger

  def follow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.follow(follower, followed) do
      {:ok, activity, _} ->
        {:ok, activity}

      e ->
        Logger.warn("Error while following actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def unfollow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.unfollow(follower, followed) do
      {:ok, activity, _} ->
        {:ok, activity}

      e ->
        Logger.warn("Error while unfollowing actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def accept(%Actor{} = follower, %Actor{} = followed) do
    with %Follower{approved: false, id: follow_id, url: follow_url} = follow <-
           Actors.is_following(follower, followed),
         activity_follow_url <- "#{MobilizonWeb.Endpoint.url()}/accept/follow/#{follow_id}",
         data <-
           ActivityPub.Utils.make_follow_data(followed, follower, follow_url),
         {:ok, activity, _} <-
           ActivityPub.accept(
             %{to: [follower.url], actor: followed.url, object: data},
             activity_follow_url
           ),
         {:ok, %Follower{approved: true}} <- Actors.update_follower(follow, %{"approved" => true}) do
      {:ok, activity}
    else
      %Follower{approved: true} ->
        {:error, "Follow already accepted"}
    end
  end
end
