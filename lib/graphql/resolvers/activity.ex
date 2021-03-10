defmodule Mobilizon.GraphQL.Resolvers.Activity do
  @moduledoc """
  Handles the activity-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Activities, Actors, Discussions, Events, Posts, Resources, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
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

      elements =
        Enum.map(elements, fn %Activity{} = activity ->
          activity
          |> Map.update(:subject_params, %{}, &transform_params/1)
          |> Map.put(:object, get_object(activity))
        end)

      {:ok, %Page{total: total, elements: elements}}
    else
      {:member, false} ->
        {:error, :unauthorized}
    end
  end

  def group_activity(_, _, _) do
    {:error, :unauthenticated}
  end

  defp get_object(%Activity{object_type: object_type, object_id: object_id}) do
    get_object(object_type, object_id)
  end

  defp get_object(_, nil), do: nil

  defp get_object(:event, event_id) do
    case Events.get_event(event_id) do
      {:ok, %Event{} = event} -> event
      _ -> nil
    end
  end

  defp get_object(:post, post_id) do
    Posts.get_post(post_id)
  end

  defp get_object(:member, member_id) do
    Actors.get_member(member_id)
  end

  defp get_object(:resource, resource_id) do
    Resources.get_resource(resource_id)
  end

  defp get_object(:discussion, discussion_id) do
    Discussions.get_discussion(discussion_id)
  end

  defp get_object(:group, group_id) do
    Actors.get_actor(group_id)
  end

  defp get_object(:comment, comment_id) do
    Discussions.get_comment(comment_id)
  end

  @spec transform_params(map()) :: list()
  defp transform_params(params) do
    Enum.map(params, fn {key, value} -> %{key: key, value: transform_value(value)} end)
  end

  defp transform_value(value) when is_list(value) do
    Enum.join(value, ",")
  end

  defp transform_value(value), do: value
end
