defmodule Mobilizon.Discussions do
  @moduledoc """
  The discussions context
  """

  import EctoEnum
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Storage.{Page, Repo}

  defenum(
    CommentVisibility,
    :comment_visibility,
    [
      :public,
      :unlisted,
      :private,
      :moderated,
      :invite
    ]
  )

  defenum(
    CommentModeration,
    :comment_moderation,
    [
      :allow_all,
      :moderated,
      :closed
    ]
  )

  @comment_preloads [
    :actor,
    :event,
    :attributed_to,
    :in_reply_to_comment,
    :origin_comment,
    :replies,
    :tags,
    :mentions,
    :discussion
  ]

  @discussion_preloads [
    :last_comment,
    :comments,
    :creator,
    :actor
  ]

  @public_visibility [:public, :unlisted]

  @doc """
  Callback for Absinthe Ecto Dataloader
  """
  # sobelow_skip ["SQL.Query"]
  @spec data :: Dataloader.Ecto.t()
  def data do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc """
  Query for comment dataloader

  We only get first comment of thread, and count replies.
  Read: https://hexdocs.pm/absinthe/ecto.html#dataloader
  """
  @spec query(atom(), map()) :: Ecto.Queryable.t()
  def query(Comment, _params) do
    Comment
    |> join(:left, [c], r in Comment, on: r.origin_comment_id == c.id)
    |> where([c, _], is_nil(c.in_reply_to_comment_id))
    # TODO: This was added because we don't want to count deleted comments in total_replies.
    # However, it also excludes all top-level comments with deleted replies from being selected
    # |> where([_, r], is_nil(r.deleted_at))
    |> group_by([c], c.id)
    |> select([c, r], %{c | total_replies: count(r.id)})
  end

  def query(queryable, _) do
    queryable
  end

  @doc """
  Gets a single comment.
  """
  @spec get_comment(integer | String.t()) :: Comment.t() | nil
  def get_comment(nil), do: nil
  def get_comment(id), do: Repo.get(Comment, id)

  @doc """
  Gets a single comment.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment!(integer | String.t()) :: Comment.t()
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Get a single comment by it's ID and all associations preloaded
  """
  @spec get_comment_with_preload(String.t() | integer() | nil) :: Comment.t() | nil
  def get_comment_with_preload(nil), do: nil

  def get_comment_with_preload(id) do
    Comment
    |> where(id: ^id)
    |> preload_for_comment()
    |> Repo.one()
  end

  @doc """
  Gets a comment by its URL.
  """
  @spec get_comment_from_url(String.t()) :: Comment.t() | nil
  def get_comment_from_url(url), do: Repo.get_by(Comment, url: url)

  @doc """
  Gets a comment by its URL.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment_from_url!(String.t()) :: Comment.t()
  def get_comment_from_url!(url), do: Repo.get_by!(Comment, url: url)

  @doc """
  Gets a comment by its URL, with all associations loaded.
  """
  @spec get_comment_from_url_with_preload(String.t()) ::
          {:ok, Comment.t()} | {:error, :comment_not_found}
  def get_comment_from_url_with_preload(url) do
    query = from(c in Comment, where: c.url == ^url)

    comment =
      query
      |> preload_for_comment()
      |> Repo.one()

    case comment do
      %Comment{} = comment ->
        {:ok, comment}

      nil ->
        {:error, :comment_not_found}
    end
  end

  @doc """
  Gets a comment by its URL, with all associations loaded.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment_from_url_with_preload(String.t()) :: Comment.t()
  def get_comment_from_url_with_preload!(url) do
    Comment
    |> Repo.get_by!(url: url)
    |> Repo.preload(@comment_preloads)
  end

  @doc """
  Gets a comment by its UUID, with all associations loaded.
  """
  @spec get_comment_from_uuid_with_preload(String.t()) :: Comment.t()
  def get_comment_from_uuid_with_preload(uuid) do
    Comment
    |> Repo.get_by(uuid: uuid)
    |> Repo.preload(@comment_preloads)
  end

  @doc """
  Get all comment threads under an event
  """
  @spec get_threads(String.t() | integer()) :: [Comment.t()]
  def get_threads(event_id) do
    Comment
    |> where([c, _], c.event_id == ^event_id and is_nil(c.origin_comment_id))
    |> join(:left, [c], r in Comment, on: r.origin_comment_id == c.id)
    |> group_by([c], c.id)
    |> select([c, r], %{c | total_replies: count(r.id)})
    |> Repo.all()
  end

  @doc """
  Gets paginated replies for root comment
  """
  @spec get_thread_replies(integer()) :: [Comment.t()]
  def get_thread_replies(parent_id) do
    parent_id
    |> public_replies_for_thread_query()
    |> Repo.all()
  end

  @doc """
  Get a comment or create it
  """
  @spec get_or_create_comment(map()) :: {:ok, Comment.t()}
  def get_or_create_comment(%{"url" => url} = attrs) do
    case Repo.get_by(Comment, url: url) do
      %Comment{} = comment -> {:ok, Repo.preload(comment, @comment_preloads)}
      nil -> create_comment(attrs)
    end
  end

  @doc """
  Creates a comment.
  """
  @spec create_comment(map) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def create_comment(attrs \\ %{}) do
    with {:ok, %Comment{} = comment} <-
           %Comment{}
           |> Comment.changeset(attrs)
           |> Repo.insert(),
         %Comment{} = comment <- Repo.preload(comment, @comment_preloads) do
      {:ok, comment}
    end
  end

  @doc """
  Updates a comment.
  """
  @spec update_comment(Comment.t(), map) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment

  But actually just empty the fields so that threads are not broken.
  """
  @spec delete_comment(Comment.t(), Keyword.t()) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def delete_comment(%Comment{} = comment, options \\ []) do
    if Keyword.get(options, :force, false) == false do
      with {:ok, %Comment{} = comment} <-
             comment
             |> Comment.delete_changeset()
             |> Repo.update(),
           %Comment{} = comment <- get_comment_with_preload(comment.id) do
        {:ok, comment}
      end
    else
      comment
      |> Repo.delete()
    end
  end

  @doc """
  Returns the list of public comments.
  """
  @spec list_comments :: [Comment.t()]
  def list_comments do
    Repo.all(from(c in Comment, where: c.visibility == ^:public))
  end

  @doc """
  Returns a paginated list of local comments
  """
  @spec list_local_comments(integer | nil, integer | nil) :: Page.t()
  def list_local_comments(page \\ nil, limit \\ nil) do
    Comment
    |> where([c], c.visibility == ^:public)
    |> where([c], is_nil(c.deleted_at))
    |> where([c], is_nil(c.discussion_id))
    |> preload_for_comment()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of public comments for the actor.
  """
  @spec list_public_comments_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def list_public_comments_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> public_comments_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of comments by an actor and a list of ids.
  """
  @spec list_comments_by_actor_and_ids(integer | String.t(), [integer | String.t()]) ::
          [Comment.t()]
  def list_comments_by_actor_and_ids(actor_id, comment_ids \\ [])
  def list_comments_by_actor_and_ids(_actor_id, []), do: []

  def list_comments_by_actor_and_ids(actor_id, comment_ids) do
    Comment
    |> where([c], c.id in ^comment_ids)
    |> where([c], c.actor_id == ^actor_id)
    |> Repo.all()
  end

  @doc """
  Get all the comments contained into a discussion
  """
  @spec get_comments_for_discussion(integer, integer | nil, integer | nil) :: Page.t()
  def get_comments_for_discussion(discussion_id, page \\ nil, limit \\ nil) do
    Comment
    |> where([c], c.discussion_id == ^discussion_id)
    |> order_by(asc: :inserted_at)
    |> Page.build_page(page, limit)
  end

  @doc """
  Counts local comments under events
  """
  @spec count_local_comments_under_events :: integer
  def count_local_comments_under_events do
    count_local_comments_query()
    |> filter_comments_under_events()
    |> Repo.one()
  end

  @doc """
  Counts all comments.
  """
  @spec count_comments_under_events :: integer
  def count_comments_under_events do
    count_comments_query()
    |> filter_comments_under_events()
    |> Repo.one()
  end

  @doc """
  Get a discussion by it's ID
  """
  @spec get_discussion(String.t() | integer()) :: Discussion.t()
  def get_discussion(discussion_id) do
    Discussion
    |> Repo.get(discussion_id)
    |> Repo.preload(@discussion_preloads)
  end

  @doc """
  Get a discussion by it's URL
  """
  @spec get_discussion_by_url(String.t() | nil) :: Discussion.t() | nil
  def get_discussion_by_url(nil), do: nil

  def get_discussion_by_url(discussion_url) do
    Discussion
    |> Repo.get_by(url: discussion_url)
    |> Repo.preload(@discussion_preloads)
  end

  @doc """
  Get a discussion by it's slug
  """
  @spec get_discussion_by_slug(String.t()) :: Discussion.t()
  def get_discussion_by_slug(discussion_slug) do
    Discussion
    |> Repo.get_by(slug: discussion_slug)
    |> Repo.preload(@discussion_preloads)
  end

  @doc """
  Get a paginated list of discussions for a group actor
  """
  @spec find_discussions_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def find_discussions_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    Discussion
    |> where([c], c.actor_id == ^actor_id)
    |> preload(^@discussion_preloads)
    |> order_by(desc: :updated_at)
    |> Page.build_page(page, limit)
  end

  @doc """
  Creates a discussion.
  """
  @spec create_discussion(map) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def create_discussion(attrs \\ %{}) do
    with {:ok, %{comment: %Comment{} = _comment, discussion: %Discussion{} = discussion}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             Comment.changeset(
               %Comment{},
               Map.merge(attrs, %{actor_id: attrs.creator_id, attributed_to_id: attrs.actor_id})
             )
           )
           |> Multi.insert(:discussion, fn %{comment: %Comment{id: comment_id}} ->
             Discussion.changeset(
               %Discussion{},
               Map.merge(attrs, %{last_comment_id: comment_id})
             )
           end)
           |> Multi.update(:comment_discussion, fn %{
                                                     comment: %Comment{} = comment,
                                                     discussion: %Discussion{
                                                       id: discussion_id,
                                                       url: discussion_url
                                                     }
                                                   } ->
             Changeset.change(comment, %{discussion_id: discussion_id, url: discussion_url})
           end)
           |> Repo.transaction() do
      {:ok, discussion}
    end
  end

  @doc """
  Create a response to a discussion
  """
  @spec reply_to_discussion(Discussion.t(), map()) :: {:ok, Discussion.t()}
  def reply_to_discussion(%Discussion{id: discussion_id} = discussion, attrs \\ %{}) do
    with {:ok, %{comment: %Comment{} = comment, discussion: %Discussion{} = discussion}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             Comment.changeset(
               %Comment{},
               Map.merge(attrs, %{
                 discussion_id: discussion_id,
                 actor_id: Map.get(attrs, :creator_id, attrs.actor_id)
               })
             )
           )
           |> Multi.update(:discussion, fn %{comment: %Comment{id: comment_id}} ->
             Discussion.changeset(
               discussion,
               %{last_comment_id: comment_id}
             )
           end)
           |> Repo.transaction() do
      # Discussion is not updated
      {:ok, Map.put(discussion, :last_comment, comment)}
    end
  end

  @doc """
  Update a discussion. Only their title for now.
  """
  @spec update_discussion(Discussion.t(), map()) ::
          {:ok, Discussion.t()} | {:error, Changeset.t()}
  def update_discussion(%Discussion{} = discussion, attrs \\ %{}) do
    discussion
    |> Discussion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a discussion.
  """
  @spec delete_discussion(Discussion.t()) :: {:ok, Discussion.t()} | {:error, Changeset.t()}
  def delete_discussion(%Discussion{id: discussion_id}) do
    Multi.new()
    |> Multi.delete_all(:comments, fn _ ->
      where(Comment, [c], c.discussion_id == ^discussion_id)
    end)
    # |> Multi.delete(:discussion, discussion)
    |> Repo.transaction()
  end

  @spec public_comments_for_actor_query(String.t() | integer()) :: [Comment.t()]
  defp public_comments_for_actor_query(actor_id) do
    Comment
    |> where([c], c.actor_id == ^actor_id and c.visibility in ^@public_visibility)
    |> order_by([c], desc: :id)
    |> preload_for_comment()
  end

  @spec public_replies_for_thread_query(String.t() | integer()) :: [Comment.t()]
  defp public_replies_for_thread_query(comment_id) do
    Comment
    |> where([c], c.origin_comment_id == ^comment_id and c.visibility in ^@public_visibility)
    |> group_by([c], [c.in_reply_to_comment_id, c.id])
    |> preload_for_comment()
  end

  @spec count_local_comments_query :: Ecto.Query.t()
  defp count_local_comments_query do
    count_comments_query()
    |> where([c], local: true)
  end

  @spec count_comments_query :: Ecto.Query.t()
  defp count_comments_query do
    from(
      c in Comment,
      select: count(c.id),
      where: c.visibility in ^@public_visibility
    )
  end

  @spec filter_comments_under_events(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_comments_under_events(query) do
    where(query, [c], is_nil(c.discussion_id) and not is_nil(c.event_id))
  end

  @spec preload_for_comment(Ecto.Query.t()) :: Ecto.Query.t()
  defp preload_for_comment(query), do: preload(query, ^@comment_preloads)
end
