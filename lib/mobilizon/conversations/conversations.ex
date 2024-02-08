defmodule Mobilizon.Conversations do
  @moduledoc """
  The conversations context
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.{Page, Repo}

  @conversation_preloads [
    :origin_comment,
    :last_comment,
    :event,
    :participants
  ]

  @comment_preloads [
    :actor,
    :event,
    :attributed_to,
    :in_reply_to_comment,
    :origin_comment,
    :replies,
    :tags,
    :mentions,
    :media
  ]

  @doc """
  Get a conversation by it's ID
  """
  @spec get_conversation(String.t() | integer()) :: Conversation.t() | nil
  def get_conversation(conversation_id) do
    Conversation
    |> Repo.get(conversation_id)
    |> Repo.preload(@conversation_preloads)
  end

  @doc """
  Get a conversation by it's ID
  """
  @spec get_conversation_participant(String.t() | integer()) :: Conversation.t() | nil
  def get_conversation_participant(conversation_participant_id) do
    preload_conversation_participant_details()
    |> where([cp], cp.id == ^conversation_participant_id)
    |> Repo.one()
  end

  def get_participant_by_conversation_and_actor(conversation_id, actor_id) do
    preload_conversation_participant_details()
    |> where([cp], cp.conversation_id == ^conversation_id and cp.actor_id == ^actor_id)
    |> Repo.one()
  end

  defp preload_conversation_participant_details do
    ConversationParticipant
    |> join(:inner, [cp], c in Conversation, on: cp.conversation_id == c.id)
    |> join(:left, [_cp, c], e in Event, on: c.event_id == e.id)
    |> join(:inner, [cp], a in Actor, on: cp.actor_id == a.id)
    |> join(:inner, [_cp, c], lc in Comment, on: c.last_comment_id == lc.id)
    |> join(:inner, [_cp, c], oc in Comment, on: c.origin_comment_id == oc.id)
    |> join(:inner, [_cp, c], p in ConversationParticipant, on: c.id == p.conversation_id)
    |> join(:inner, [_cp, _c, _e, _a, _lc, _oc, p], ap in Actor, on: p.actor_id == ap.id)
    |> preload([_cp, c, e, a, lc, oc, p, ap],
      actor: a,
      conversation:
        {c, event: e, last_comment: lc, origin_comment: oc, participants: {p, actor: ap}}
    )
  end

  @doc """
  Get a paginated list of conversations for an actor
  """
  @spec find_conversations_for_actor(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Conversation.t())
  def find_conversations_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    Conversation
    |> where([c], c.actor_id == ^actor_id)
    |> preload(^@conversation_preloads)
    |> order_by(desc: :updated_at)
    |> Page.build_page(page, limit)
  end

  @spec find_conversations_for_event(
          String.t() | integer,
          String.t() | integer,
          integer | nil,
          integer | nil
        ) :: Page.t(ConversationParticipant.t())
  def find_conversations_for_event(event_id, actor_id, page \\ nil, limit \\ nil) do
    ConversationParticipant
    |> join(:inner, [cp], c in Conversation, on: cp.conversation_id == c.id)
    |> join(:left, [_cp, c], e in Event, on: c.event_id == e.id)
    |> join(:inner, [cp], a in Actor, on: cp.actor_id == a.id)
    |> join(:inner, [_cp, c], lc in Comment, on: c.last_comment_id == lc.id)
    |> join(:inner, [_cp, c], oc in Comment, on: c.origin_comment_id == oc.id)
    |> join(:inner, [_cp, c], p in ConversationParticipant, on: c.id == p.conversation_id)
    |> join(:inner, [_cp, _c, _e, _a, _lc, _oc, p], ap in Actor, on: p.actor_id == ap.id)
    |> where([_cp, c], c.event_id == ^event_id)
    |> where([cp], cp.actor_id == ^actor_id)
    |> where(
      [_cp, _c, _e, _a, _lc, oc],
      oc.actor_id == ^actor_id or oc.attributed_to_id == ^actor_id
    )
    |> order_by([cp], desc: cp.unread, desc: cp.updated_at)
    |> preload([_cp, c, e, a, lc, oc, p, ap],
      actor: a,
      conversation:
        {c, event: e, last_comment: lc, origin_comment: oc, participants: {p, actor: ap}}
    )
    |> Page.build_page(page, limit)
  end

  def find_all_conversations_for_event(event_id) do
    ConversationParticipant
    |> join(:inner, [cp], c in Conversation, on: cp.conversation_id == c.id)
    |> join(:left, [_cp, c], e in Event, on: c.event_id == e.id)
    |> where([_cp, c], c.event_id == ^event_id)
    |> Repo.all()
  end

  @spec list_conversation_participants_for_actor(
          integer | String.t(),
          integer | nil,
          integer | nil
        ) ::
          Page.t(ConversationParticipant.t())
  def list_conversation_participants_for_actor(actor_id, page \\ nil, limit \\ nil) do
    subquery =
      ConversationParticipant
      |> distinct([cp], cp.conversation_id)
      |> join(:left, [cp], m in Member, on: cp.actor_id == m.parent_id)
      |> where([cp], cp.actor_id == ^actor_id)
      |> or_where(
        [_cp, m],
        m.actor_id == ^actor_id and m.role in [:creator, :administrator, :moderator]
      )

    subquery
    |> subquery()
    |> order_by([cp], desc: cp.unread, desc: cp.updated_at)
    |> preload([:actor, conversation: [:last_comment, :origin_comment, :participants, :event]])
    |> Page.build_page(page, limit)
  end

  @spec list_conversation_participants_for_user(
          integer | String.t(),
          integer | nil,
          integer | nil
        ) ::
          Page.t(ConversationParticipant.t())
  def list_conversation_participants_for_user(user_id, page \\ nil, limit \\ nil) do
    ConversationParticipant
    |> join(:inner, [cp], a in Actor, on: cp.actor_id == a.id)
    |> where([_cp, a], a.user_id == ^user_id)
    |> preload([:actor, conversation: [:last_comment, :origin_comment, :participants, :event]])
    |> Page.build_page(page, limit)
  end

  @spec list_conversation_participants_for_conversation(integer | String.t()) ::
          list(ConversationParticipant.t())
  def list_conversation_participants_for_conversation(conversation_id) do
    ConversationParticipant
    |> where([cp], cp.conversation_id == ^conversation_id)
    |> Repo.all()
  end

  @spec count_unread_conversation_participants_for_person(integer | String.t()) ::
          non_neg_integer()
  def count_unread_conversation_participants_for_person(actor_id) do
    ConversationParticipant
    |> where([cp], cp.actor_id == ^actor_id and cp.unread == true)
    |> Repo.aggregate(:count)
  end

  @doc """
  Creates a conversation.
  """
  @spec create_conversation(map()) ::
          {:ok, Conversation.t()} | {:error, atom(), Changeset.t(), map()}
  def create_conversation(attrs) do
    with {:ok, %{comment: %Comment{} = _comment, conversation: %Conversation{} = conversation}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             Comment.changeset(
               %Comment{},
               Map.merge(attrs, %{
                 actor_id: attrs.actor_id,
                 attributed_to_id: attrs.actor_id,
                 visibility: :private
               })
             )
           )
           |> Multi.insert(:conversation, fn %{
                                               comment: %Comment{
                                                 id: comment_id,
                                                 origin_comment_id: origin_comment_id
                                               }
                                             } ->
             Conversation.changeset(
               %Conversation{},
               Map.merge(attrs, %{
                 last_comment_id: comment_id,
                 origin_comment_id: origin_comment_id || comment_id,
                 participants: attrs.participants
               })
             )
           end)
           |> Multi.update(:update_comment, fn %{
                                                 comment: %Comment{} = comment,
                                                 conversation: %Conversation{id: conversation_id}
                                               } ->
             Comment.changeset(
               comment,
               %{conversation_id: conversation_id}
             )
           end)
           |> Multi.update_all(
             :conversation_participants,
             fn %{
                  conversation: %Conversation{
                    id: conversation_id
                  }
                } ->
               ConversationParticipant
               |> where(
                 [cp],
                 cp.conversation_id == ^conversation_id and cp.actor_id == ^attrs.actor_id
               )
               |> update([cp], set: [unread: false, updated_at: ^NaiveDateTime.utc_now()])
             end,
             []
           )
           |> Repo.transaction(),
         %Conversation{} = conversation <- Repo.preload(conversation, @conversation_preloads) do
      {:ok, conversation}
    end
  end

  @doc """
  Create a response to a conversation
  """
  @spec reply_to_conversation(Conversation.t(), map()) ::
          {:ok, Conversation.t()} | {:error, atom(), Ecto.Changeset.t(), map()}
  def reply_to_conversation(%Conversation{id: conversation_id} = conversation, attrs \\ %{}) do
    attrs =
      Map.merge(attrs, %{
        conversation_id: conversation_id,
        actor_id: Map.get(attrs, :creator_id, Map.get(attrs, :actor_id)),
        origin_comment_id: conversation.origin_comment_id,
        in_reply_to_comment_id: conversation.last_comment_id,
        visibility: :private
      })

    changeset =
      Comment.changeset(
        %Comment{},
        attrs
      )

    with {:ok, %{comment: %Comment{} = comment, conversation: %Conversation{} = conversation}} <-
           Multi.new()
           |> Multi.insert(
             :comment,
             changeset
           )
           |> Multi.update(:conversation, fn %{comment: %Comment{id: comment_id}} ->
             Conversation.changeset(
               conversation,
               %{last_comment_id: comment_id}
             )
           end)
           |> Multi.update_all(
             :conversation_participants,
             fn %{
                  conversation: %Conversation{
                    id: conversation_id
                  }
                } ->
               ConversationParticipant
               |> where(
                 [cp],
                 cp.conversation_id == ^conversation_id and cp.actor_id != ^attrs.actor_id
               )
               |> update([cp], set: [unread: true, updated_at: ^NaiveDateTime.utc_now()])
             end,
             []
           )
           |> Multi.update_all(
             :conversation_participants_author,
             fn %{
                  conversation: %Conversation{
                    id: conversation_id
                  }
                } ->
               ConversationParticipant
               |> where(
                 [cp],
                 cp.conversation_id == ^conversation_id and cp.actor_id == ^attrs.actor_id
               )
               |> update([cp], set: [unread: false, updated_at: ^NaiveDateTime.utc_now()])
             end,
             []
           )
           |> Repo.transaction(),
         # Conversation is not updated
         %Comment{} = comment <- Repo.preload(comment, @comment_preloads) do
      {:ok, %Conversation{conversation | last_comment: comment}}
    end
  end

  @doc """
  Update a conversation.
  """
  @spec update_conversation(Conversation.t(), map()) ::
          {:ok, Conversation.t()} | {:error, Changeset.t()}
  def update_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a conversation.
  """
  @spec delete_conversation(Conversation.t()) ::
          {:ok, %{comments: {integer() | nil, any()}}} | {:error, :comments, Changeset.t(), map()}
  def delete_conversation(%Conversation{id: conversation_id}) do
    Multi.new()
    |> Multi.delete_all(:comments, fn _ ->
      where(Comment, [c], c.conversation_id == ^conversation_id)
    end)
    # |> Multi.delete(:conversation, conversation)
    |> Repo.transaction()
  end

  @doc """
  Update a conversation participant. Only their read status for now
  """
  @spec update_conversation_participant(ConversationParticipant.t(), map()) ::
          {:ok, ConversationParticipant.t()} | {:error, Changeset.t()}
  def update_conversation_participant(
        %ConversationParticipant{} = conversation_participant,
        attrs \\ %{}
      ) do
    conversation_participant
    |> ConversationParticipant.changeset(attrs)
    |> Repo.update()
  end
end
