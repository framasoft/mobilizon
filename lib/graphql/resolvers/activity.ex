defmodule Mobilizon.GraphQL.Resolvers.Activity do
  @moduledoc """
  Handles the activity-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Activities, Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Utils
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  require Logger

  def group_activity(%Actor{type: :Group, id: group_id}, %{page: page, limit: limit} = args, %{
        context: %{current_user: %User{role: role} = user}
      }) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id) or is_moderator(role)} do
      %Page{total: total, elements: elements} =
        Activities.list_group_activities_for_member(
          group_id,
          actor_id,
          [type: Map.get(args, :type), author: Map.get(args, :author)],
          page,
          limit
        )

      elements = Enum.map(elements, &Utils.transform_activity/1)

      {:ok, %Page{total: total, elements: elements}}
    else
      {:member, false} ->
        {:error, :unauthorized}
    end
  end

  def group_activity(_, _, _) do
    {:error, :unauthenticated}
  end
end
