defmodule Mobilizon.Service.Activity do
  @moduledoc """
  Behavior for Activity creators
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Service.Activity.{Comment, Discussion, Event, Group, Member, Post, Resource}

  @callback insert_activity(entity :: struct(), options :: map()) ::
              {:ok, Oban.Job.t()} | {:ok, any()}

  @callback get_object(object_id :: String.t() | integer()) :: struct()

  @spec object(Activity.t()) :: struct() | nil
  def object(%Activity{object_type: object_type, object_id: object_id}) do
    do_get_object(object_type, object_id)
  end

  defp do_get_object(_, nil), do: nil

  defp do_get_object(:event, event_id) do
    Event.get_object(event_id)
  end

  defp do_get_object(:post, post_id) do
    Post.get_object(post_id)
  end

  defp do_get_object(:member, member_id) do
    Member.get_object(member_id)
  end

  defp do_get_object(:resource, resource_id) do
    Resource.get_object(resource_id)
  end

  defp do_get_object(:discussion, discussion_id) do
    Discussion.get_object(discussion_id)
  end

  defp do_get_object(:group, group_id) do
    Group.get_object(group_id)
  end

  defp do_get_object(:comment, comment_id) do
    Comment.get_object(comment_id)
  end
end
