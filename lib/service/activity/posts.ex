defmodule Mobilizon.Service.Activity.Post do
  @moduledoc """
  Insert an post activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(post, options \\ [])

  def insert_activity(
        %Post{attributed_to_id: attributed_to_id, author_id: author_id} = post,
        options
      )
      when not is_nil(attributed_to_id) do
    author = Actors.get_actor(author_id)
    group = Actors.get_actor(attributed_to_id)
    subject = Keyword.fetch!(options, :subject)

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "post",
      "subject" => subject,
      "subject_params" => %{post_slug: post.slug, post_title: post.title},
      "group_id" => group.id,
      "author_id" => author.id,
      "object_type" => "post",
      "object_id" => if(subject != "post_deleted", do: to_string(post.id), else: nil),
      "inserted_at" => DateTime.utc_now()
    })
  end

  def insert_activity(_, _), do: {:ok, nil}
end
