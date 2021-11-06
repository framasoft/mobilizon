defmodule Mobilizon.GraphQL.Resolvers.Followers do
  @moduledoc """
  Handles the followers-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @spec find_followers_for_group(Actor.t(), map(), map()) :: {:ok, Page.t()}
  def find_followers_for_group(
        %Actor{id: group_id} = group,
        args,
        %{
          context: %{
            current_user: %User{role: user_role},
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    followers = group_followers(group, args)

    if Actors.is_moderator?(actor_id, group_id) or is_moderator(user_role) do
      {:ok, followers}
    else
      {:ok, %Page{followers | elements: []}}
    end
  end

  def find_followers_for_group(%Actor{} = group, args, _) do
    followers = group_followers(group, args)
    {:ok, %Page{followers | elements: []}}
  end

  defp group_followers(group, %{page: page, limit: limit} = args) do
    Actors.list_paginated_followers_for_actor(group, Map.get(args, :approved), page, limit)
  end

  @spec update_follower(any(), map(), map()) :: {:ok, Follower.t()} | {:error, any()}
  def update_follower(_, %{id: follower_id, approved: approved}, %{
        context: %{
          current_actor: %Actor{id: actor_id}
        }
      }) do
    with %Follower{target_actor: %Actor{type: :Group, id: group_id}} = follower <-
           Actors.get_follower(follower_id),
         {:member, true} <-
           {:member, Actors.is_moderator?(actor_id, group_id)},
         {:ok, _activity, %Follower{} = follower} <-
           (if approved do
              Actions.Accept.accept(:follow, follower)
            else
              Actions.Reject.reject(:follow, follower)
            end) do
      {:ok, follower}
    else
      {:member, _} ->
        {:error, :unauthorized}

      _ ->
        {:error,
         if(approved, do: "Unable to approve follower", else: "Unable to reject follower")}
    end
  end

  def update_follower(_, _, _), do: {:error, :unauthenticated}
end
