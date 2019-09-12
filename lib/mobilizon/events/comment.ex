defmodule Mobilizon.Events.Comment do
  @moduledoc """
  Represents an actor comment (for instance on an event or on a group).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.{Comment, CommentVisibility, Event}

  @type t :: %__MODULE__{
          text: String.t(),
          url: String.t(),
          local: boolean,
          visibility: CommentVisibility.t(),
          uuid: Ecto.UUID.t(),
          actor: Actor.t(),
          attributed_to: Actor.t(),
          event: Event.t(),
          in_reply_to_comment: t,
          origin_comment: t
        }

  @required_attrs [:text, :actor_id, :url]
  @optional_attrs [:event_id, :in_reply_to_comment_id, :origin_comment_id, :attributed_to_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "comments" do
    field(:text, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:visibility, CommentVisibility, default: :public)
    field(:uuid, Ecto.UUID)

    belongs_to(:actor, Actor, foreign_key: :actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:event, Event, foreign_key: :event_id)
    belongs_to(:in_reply_to_comment, Comment, foreign_key: :in_reply_to_comment_id)
    belongs_to(:origin_comment, Comment, foreign_key: :origin_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the id of the first comment in the conversation.
  """
  @spec get_thread_id(t) :: integer
  def get_thread_id(%__MODULE__{id: id, origin_comment_id: origin_comment_id}) do
    origin_comment_id || id
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = comment, attrs) do
    uuid = attrs["uuid"] || Ecto.UUID.generate()
    url = attrs["url"] || generate_url(uuid)

    comment
    |> cast(attrs, @attrs)
    |> put_change(:uuid, uuid)
    |> put_change(:url, url)
    |> validate_required(@required_attrs)
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(uuid), do: "#{Config.instance_hostname()}/comments/#{uuid}"
end
