defmodule Mobilizon.Service.Activity.Discussion do
  @moduledoc """
  Insert a discussion activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(discussion, options \\ [])

  def insert_activity(
        %Discussion{creator_id: creator_id, actor_id: actor_id} = discussion,
        options
      )
      when not is_nil(creator_id) do
    creator = Actors.get_actor(creator_id)
    group = Actors.get_actor(actor_id)
    subject = Keyword.fetch!(options, :subject)
    author = Keyword.get(options, :moderator, creator)
    author_id = Keyword.get(options, :actor_id, author.id)
    old_discussion = Keyword.get(options, :old_discussion)

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "discussion",
      "subject" => subject,
      "subject_params" => subject_params(discussion, subject, old_discussion),
      "group_id" => group.id,
      "author_id" => author_id,
      "object_type" => "discussion",
      "object_id" => if(subject != "discussion_deleted", do: to_string(discussion.id), else: nil),
      "inserted_at" => DateTime.utc_now()
    })
  end

  def insert_activity(_, _), do: {:ok, nil}

  @spec subject_params(Discussion.t(), String.t() | nil, Discussion.t() | nil) :: map()
  defp subject_params(%Discussion{} = discussion, "discussion_renamed", old_discussion) do
    discussion
    |> subject_params(nil, nil)
    |> Map.put(:old_discussion_title, old_discussion.title)
  end

  defp subject_params(%Discussion{} = discussion, _, _) do
    %{discussion_slug: discussion.slug, discussion_title: discussion.title}
  end
end
