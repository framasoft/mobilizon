defmodule Mobilizon.Discussions.Comment do
  @moduledoc """
  Represents an actor comment (for instance on an event or on a group).
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Mobilizon.Storage.Ecto, only: [maybe_add_published_at: 1]

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, CommentVisibility, Discussion}
  alias Mobilizon.Events.{Event, Tag}
  alias Mobilizon.Medias.Media
  alias Mobilizon.Mention

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @type t :: %__MODULE__{
          text: String.t(),
          url: String.t(),
          local: boolean,
          visibility: CommentVisibility.t(),
          uuid: Ecto.UUID.t(),
          actor: Actor.t(),
          attributed_to: Actor.t(),
          event: Event.t(),
          tags: [Tag.t()],
          mentions: [Mention.t()],
          media: [Media.t()],
          in_reply_to_comment: t,
          origin_comment: t
        }

  # When deleting an event we only nihilify everything
  @required_attrs [:url]
  @creation_required_attrs @required_attrs ++ [:text, :actor_id, :published_at]
  @optional_attrs [
    :text,
    :actor_id,
    :event_id,
    :in_reply_to_comment_id,
    :origin_comment_id,
    :attributed_to_id,
    :deleted_at,
    :local,
    :discussion_id
  ]
  @attrs @required_attrs ++ @optional_attrs

  schema "comments" do
    field(:text, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:visibility, CommentVisibility, default: :public)
    field(:uuid, Ecto.UUID)
    field(:total_replies, :integer, virtual: true, default: 0)
    field(:deleted_at, :utc_datetime)
    field(:published_at, :utc_datetime)

    belongs_to(:actor, Actor, foreign_key: :actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:event, Event, foreign_key: :event_id)
    belongs_to(:in_reply_to_comment, Comment, foreign_key: :in_reply_to_comment_id)
    belongs_to(:origin_comment, Comment, foreign_key: :origin_comment_id)
    belongs_to(:discussion, Discussion, type: :binary_id)
    has_many(:replies, Comment, foreign_key: :in_reply_to_comment_id)
    many_to_many(:tags, Tag, join_through: "comments_tags", on_replace: :delete)
    has_many(:mentions, Mention)
    many_to_many(:media, Media, join_through: "comments_medias", on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the id of the first comment in the discussion.
  """
  @spec get_thread_id(t) :: integer
  def get_thread_id(%__MODULE__{id: id, origin_comment_id: origin_comment_id}) do
    origin_comment_id || id
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = comment, attrs) do
    comment
    |> common_changeset(attrs)
    |> validate_required(@creation_required_attrs)
  end

  def update_changeset(%__MODULE__{} = comment, attrs) do
    comment
    |> changeset(attrs)

    # TODO handle comment edits
    # |> put_change(:edits, comment.edits + 1)
  end

  @spec delete_changeset(t) :: Ecto.Changeset.t()
  def delete_changeset(%__MODULE__{} = comment) do
    comment
    |> change()
    |> put_change(:text, nil)
    |> put_change(:actor_id, nil)
    |> put_change(:deleted_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Checks whether an comment can be managed.
  """
  @spec can_be_managed_by(t, integer | String.t()) :: boolean
  def can_be_managed_by(%__MODULE__{actor_id: creator_actor_id}, actor_id)
      when creator_actor_id == actor_id do
    {:comment_can_be_managed, true}
  end

  def can_be_managed_by(_comment, _actor), do: {:comment_can_be_managed, false}

  defp common_changeset(%__MODULE__{} = comment, attrs) do
    comment
    |> cast(attrs, @attrs)
    |> maybe_add_published_at()
    |> maybe_generate_uuid()
    |> maybe_generate_url()
    |> put_assoc(:media, Map.get(attrs, :media, []))
    |> put_tags(attrs)
    |> put_mentions(attrs)
  end

  @spec maybe_generate_uuid(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_generate_uuid(%Ecto.Changeset{} = changeset) do
    case fetch_field(changeset, :uuid) do
      :error -> put_change(changeset, :uuid, Ecto.UUID.generate())
      {:data, nil} -> put_change(changeset, :uuid, Ecto.UUID.generate())
      _ -> changeset
    end
  end

  @spec maybe_generate_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_generate_url(%Ecto.Changeset{} = changeset) do
    with res when res in [:error, {:data, nil}] <- fetch_field(changeset, :url),
         {changes, uuid} when changes in [:changes, :data] <- fetch_field(changeset, :uuid),
         url <- generate_url(uuid) do
      put_change(changeset, :url, url)
    else
      _ -> changeset
    end
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(uuid), do: Routes.page_url(Endpoint, :comment, uuid)

  @spec put_tags(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_tags(changeset, %{"tags" => tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, %{tags: tags}),
    do: put_assoc(changeset, :tags, Enum.map(tags, &process_tag/1))

  defp put_tags(changeset, _), do: changeset

  @spec put_mentions(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_mentions(changeset, %{"mentions" => mentions}),
    do: put_assoc(changeset, :mentions, Enum.map(mentions, &process_mention/1))

  defp put_mentions(changeset, %{mentions: mentions}),
    do: put_assoc(changeset, :mentions, Enum.map(mentions, &process_mention/1))

  defp put_mentions(changeset, _), do: changeset

  # We need a changeset instead of a raw struct because of slug which is generated in changeset
  defp process_tag(tag) do
    Tag.changeset(%Tag{}, tag)
  end

  defp process_mention(tag) do
    Mention.changeset(%Mention{}, tag)
  end
end
