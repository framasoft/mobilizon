defmodule Mobilizon.Events.TagRelation do
  @moduledoc """
  Represents a tag relation.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.Tag

  @type t :: %__MODULE__{
          weight: integer,
          tag: Tag.t(),
          link: Tag.t()
        }

  @required_attrs [:tag_id, :link_id]
  @optional_attrs [:weight]
  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  schema "tag_relations" do
    field(:weight, :integer, default: 1)

    belongs_to(:tag, Tag, primary_key: true)
    belongs_to(:link, Tag, primary_key: true)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = tag, attrs) do
    # Return if tag_id or link_id are not set because it will fail later otherwise
    with %Ecto.Changeset{errors: [], changes: changes} = changeset <-
           tag
           |> cast(attrs, @attrs)
           |> validate_required(@required_attrs) do
      changeset
      |> put_change(:tag_id, min(changes.tag_id, changes.link_id))
      |> put_change(:link_id, max(changes.tag_id, changes.link_id))
      |> unique_constraint(:tag_id, name: :tag_relations_pkey)
      |> check_constraint(:tag_id,
        name: :no_self_loops_check,
        message: "Can't add a relation on self"
      )
    end
  end
end
