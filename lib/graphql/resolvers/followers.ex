defmodule Mobilizon.GraphQL.Resolvers.Followers do
  @moduledoc """
  Handles the followers-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @spec find_followers_for_group(Actor.t(), map(), map()) :: {:ok, Page.t()}
  def find_followers_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit} = args,
        %{
          context: %{
            current_user: %User{role: user_role} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <-
           {:member, Actors.is_moderator?(actor_id, group_id) or is_moderator(user_role)} do
      {:ok,
       Actors.list_paginated_followers_for_actor(group, Map.get(args, :approved), page, limit)}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def find_followers_for_group(_, _, _), do: {:error, :unauthenticated}

  @spec update_follower(any(), map(), map()) :: {:ok, Follower.t()} | {:error, any()}
  def update_follower(_, %{id: follower_id, approved: approved}, %{
        context: %{
          current_user: %User{} = user
        }
      }) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         %Follower{target_actor: %Actor{type: :Group, id: group_id}} = follower <-
           Actors.get_follower(follower_id),
         {:member, true} <-
           {:member, Actors.is_moderator?(actor_id, group_id)},
         {:ok, _activity, %Follower{} = follower} <-
           (if approved do
              ActivityPub.accept(:follow, follower)
            else
              ActivityPub.reject(:follow, follower)
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
