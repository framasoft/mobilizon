defmodule Eventos.Events.Comment do
  @moduledoc """
  An actor comment (for instance on an event or on a group)
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eventos.Events.Event
  alias Eventos.Actors.Actor
  alias Eventos.Actors.Comment

  schema "comments" do
    field(:text, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:uuid, Ecto.UUID)
    belongs_to(:actor, Actor, foreign_key: :actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:event, Event, foreign_key: :event_id)
    belongs_to(:in_reply_to_comment, Comment, foreign_key: :in_reply_to_comment_id)
    belongs_to(:origin_comment, Comment, foreign_key: :origin_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    uuid = Ecto.UUID.generate()

    # TODO : really change me right away
    url =
      if Map.has_key?(attrs, "url"),
        do: attrs["url"],
        else: "#{EventosWeb.Endpoint.url()}/comments/#{uuid}"

    comment
    |> cast(attrs, [:url, :text, :actor_id, :event_id, :in_reply_to_comment_id, :attributed_to_id])
    |> put_change(:uuid, uuid)
    |> put_change(:url, url)
    |> validate_required([:text, :actor_id, :url])
  end
end
