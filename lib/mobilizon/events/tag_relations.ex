defmodule Mobilizon.Events.TagRelation do
  @moduledoc """
  Represents a tag for events
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.Tag
  alias Mobilizon.Events.TagRelation

  @primary_key false
  schema "tag_relations" do
    belongs_to(:tag, Tag, primary_key: true)
    belongs_to(:link, Tag, primary_key: true)
    field(:weight, :integer, default: 1)
  end

  @doc false
  def changeset(%TagRelation{} = tag, attrs) do
    changeset =
      tag
      |> cast(attrs, [:tag_id, :link_id, :weight])
      |> validate_required([:tag_id, :link_id])

    # Return if tag_id or link_id are not set because it will fail later otherwise
    with %Ecto.Changeset{errors: []} <- changeset do
      changes = changeset.changes

      changeset =
        changeset
        |> put_change(:tag_id, min(changes.tag_id, changes.link_id))
        |> put_change(:link_id, max(changes.tag_id, changes.link_id))

      changeset
      |> unique_constraint(:tag_id, name: :tag_relations_pkey)
      |> check_constraint(:tag_id,
        name: :no_self_loops_check,
        message: "Can't add a relation on self"
      )
    end
  end
end
