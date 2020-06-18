defmodule Mobilizon.Conversations do
  @moduledoc """
  The conversations context
  """

  import EctoEnum
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.{Comment, Conversation}
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
    :mentions
  ]

  @conversation_preloads [
    :last_comment,
    :comments,
    :creator,
    :actor
  ]

  @public_visibility [:public, :unlisted]

  def data do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc """
  Query for comment dataloader

  We only get first comment of thread, and count replies.
  Read: https://hexdocs.pm/absinthe/ecto.html#dataloader
  """
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
  @spec delete_comment(Comment.t()) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def delete_comment(%Comment{} = comment) do
    comment
    |> Comment.delete_changeset()
    |> Repo.update()
  end

  @doc """
  Returns the list of public comments.
  """
  @spec list_comments :: [Comment.t()]
  def list_comments do
    Repo.all(from(c in Comment, where: c.visibility == ^:public))
  end

  @doc """
  Returns the list of public comments for the actor.
  """
  @spec list_public_comments_for_actor(Actor.t(), integer | nil, integer | nil) ::
          {:ok, [Comment.t()], integer}
  def list_public_comments_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    comments =
      actor_id
      |> public_comments_for_actor_query()
      |> Page.paginate(page, limit)
      |> Repo.all()

    count_comments =
      actor_id
      |> count_comments_query()
      |> Repo.one()

    {:ok, comments, count_comments}
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

  @spec get_comments_for_conversation(integer, integer | nil, integer | nil) :: Page.t()
  def get_comments_for_conversation(conversation_id, page \\ nil, limit \\ nil) do
    Comment
    |> where([c], c.conversation_id == ^conversation_id)
    |> order_by(asc: :inserted_at)
    |> Page.build_page(page, limit)
  end

  @doc """
  Counts local comments.
  """
  @spec count_local_comments :: integer
  def count_local_comments, do: Repo.one(count_local_comments_query())

  def get_conversation(conversation_id) do
    Conversation
    |> Repo.get(conversation_id)
    |> Repo.preload(@conversation_preloads)
  end

  @spec find_conversations_for_actor(integer, integer | nil, integer | nil) :: Page.t()
  def find_conversations_for_actor(actor_id, page \\ nil, limit \\ nil) do
    Conversation
    |> where([c], c.actor_id == ^actor_id)
    |> preload(^@conversation_preloads)
    |> Page.build_page(page, limit)
  end

  @doc """
  Creates a conversation.
  """
  @spec create_conversation(map) :: {:ok, Comment.t()} | {:error, Changeset.t()}
  def create_conversation(attrs \\ %{}) do
    with {:ok, %{comment: %Comment{} = _comment, conversation: %Conversation{} = conversation}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             Comment.changeset(%Comment{}, Map.merge(attrs, %{actor_id: attrs.creator_id}))
           )
           |> Multi.insert(:conversation, fn %{comment: %Comment{id: comment_id}} ->
             Conversation.changeset(
               %Conversation{},
               Map.merge(attrs, %{last_comment_id: comment_id})
             )
           end)
           |> Multi.update(:comment_conversation, fn %{
                                                       comment: %Comment{} = comment,
                                                       conversation: %Conversation{
                                                         id: conversation_id
                                                       }
                                                     } ->
             Changeset.change(comment, %{conversation_id: conversation_id})
           end)
           |> Repo.transaction() do
      {:ok, conversation}
    end
  end

  def reply_to_conversation(%Conversation{id: conversation_id} = conversation, attrs \\ %{}) do
    with {:ok, %{comment: %Comment{} = comment, conversation: %Conversation{} = conversation}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             Comment.changeset(%Comment{}, Map.merge(attrs, %{conversation_id: conversation_id}))
           )
           |> Multi.update(:conversation, fn %{comment: %Comment{id: comment_id}} ->
             Conversation.changeset(
               conversation,
               %{last_comment_id: comment_id}
             )
           end)
           |> Repo.transaction() do
      # For some reason conversation is not updated
      {:ok, Map.put(conversation, :last_comment, comment)}
    end
  end

  @doc """
  Update a conversation. Only their title for now.
  """
  @spec update_conversation(Conversation.t(), map()) ::
          {:ok, Conversation.t()} | {:error, Changeset.t()}
  def update_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  defp public_comments_for_actor_query(actor_id) do
    Comment
    |> where([c], c.actor_id == ^actor_id and c.visibility in ^@public_visibility)
    |> order_by([c], desc: :id)
    |> preload_for_comment()
  end

  defp public_replies_for_thread_query(comment_id) do
    Comment
    |> where([c], c.origin_comment_id == ^comment_id and c.visibility in ^@public_visibility)
    |> group_by([c], [c.in_reply_to_comment_id, c.id])
    |> preload_for_comment()
  end

  @spec count_comments_query(integer) :: Ecto.Query.t()
  defp count_comments_query(actor_id) do
    from(c in Comment, select: count(c.id), where: c.actor_id == ^actor_id)
  end

  @spec count_local_comments_query :: Ecto.Query.t()
  defp count_local_comments_query do
    from(
      c in Comment,
      select: count(c.id),
      where: c.local == ^true and c.visibility in ^@public_visibility
    )
  end

  @spec preload_for_comment(Ecto.Query.t()) :: Ecto.Query.t()
  defp preload_for_comment(query), do: preload(query, ^@comment_preloads)

  #  @spec preload_for_conversation(Ecto.Query.t()) :: Ecto.Query.t()
  #  defp preload_for_conversation(query), do: preload(query, ^@conversation_preloads)
end
