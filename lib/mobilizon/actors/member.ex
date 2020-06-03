defmodule Mobilizon.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.{Actor, MemberRole}
  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          role: MemberRole.t(),
          parent: Actor.t(),
          actor: Actor.t()
        }

  @required_attrs [:parent_id, :actor_id, :url]
  @optional_attrs [:role, :invited_by_id]
  @attrs @required_attrs ++ @optional_attrs
  @metadata_attrs []

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "members" do
    field(:role, MemberRole, default: :member)
    field(:url, :string)

    embeds_one :metadata, Metadata, on_replace: :delete do
      # TODO : Use this space to put notes when someone is invited / requested to join
    end

    belongs_to(:invited_by, Actor)
    belongs_to(:parent, Actor)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc """
  Gets the default member role depending on the actor openness.
  """
  @spec get_default_member_role(Actor.t()) :: atom
  def get_default_member_role(%Actor{openness: :open}), do: :member
  def get_default_member_role(%Actor{}), do: :not_approved

  @doc """
  Checks whether the actor can be joined to the group.
  """
  def can_be_joined(%Actor{type: :Group, openness: :invite_only}), do: false
  def can_be_joined(%Actor{type: :Group}), do: true

  @doc """
  Checks whether the member is an administrator (admin or creator) of the group.
  """
  def is_administrator(%__MODULE__{role: :administrator}), do: true
  def is_administrator(%__MODULE__{role: :creator}), do: true
  def is_administrator(%__MODULE__{}), do: false

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = member, attrs) do
    member
    |> cast(attrs, @attrs)
    |> cast_embed(:metadata, with: &metadata_changeset/2)
    |> ensure_url()
    |> validate_required(@required_attrs)
    # On both parent_id and actor_id
    |> unique_constraint(:parent_id, name: :members_actor_parent_unique_index)
    |> unique_constraint(:url, name: :members_url_index)
  end

  defp metadata_changeset(schema, params) do
    schema
    |> cast(params, @metadata_attrs)
  end

  # If there's a blank URL that's because we're doing the first insert
  @spec ensure_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp ensure_url(%Ecto.Changeset{data: %__MODULE__{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        generate_url(changeset)
    end
  end

  # Most time just go with the given URL
  defp ensure_url(%Ecto.Changeset{} = changeset), do: changeset

  @spec generate_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp generate_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(:id, uuid)
    |> put_change(:url, "#{Endpoint.url()}/member/#{uuid}")
  end
end
