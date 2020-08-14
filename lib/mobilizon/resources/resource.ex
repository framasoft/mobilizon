defmodule Mobilizon.Resources.Resource do
  @moduledoc """
  Represents a web resource
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  import Mobilizon.Storage.Ecto, only: [ensure_url: 2, maybe_add_published_at: 1]

  import EctoEnum
  defenum(TypeEnum, folder: 0, link: 1, picture: 20, pad: 30, calc: 40, visio: 50)
  alias Mobilizon.Actors.Actor

  @type t :: %__MODULE__{
          title: String.t(),
          summary: String.t(),
          url: String.t(),
          resource_url: String.t(),
          type: atom(),
          metadata: Mobilizon.Resources.Resource.Metadata.t(),
          children: list(__MODULE__),
          parent: __MODULE__,
          actor: Actor.t(),
          creator: Actor.t(),
          local: boolean,
          published_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "resource" do
    field(:summary, :string)
    field(:title, :string)
    field(:url, :string)
    field(:resource_url, :string)
    field(:type, TypeEnum)
    field(:path, :string)
    field(:local, :boolean, default: true)
    field(:published_at, :utc_datetime)

    embeds_one :metadata, Metadata, on_replace: :delete do
      field(:type, :string)
      field(:title, :string)
      field(:description, :string)
      field(:image_remote_url, :string)
      field(:width, :integer)
      field(:height, :integer)
      field(:author_name, :string)
      field(:author_url, :string)
      field(:provider_name, :string)
      field(:provider_url, :string)
      field(:html, :string)
      field(:favicon_url, :string)
    end

    has_many(:children, __MODULE__, foreign_key: :parent_id)
    belongs_to(:parent, __MODULE__, type: :binary_id)
    belongs_to(:actor, Actor)
    belongs_to(:creator, Actor)

    timestamps()
  end

  @required_attrs [:title, :url, :actor_id, :creator_id, :type, :path, :published_at]
  @optional_attrs [:summary, :parent_id, :resource_url, :local]
  @attrs @required_attrs ++ @optional_attrs
  @metadata_attrs [
    :type,
    :title,
    :description,
    :image_remote_url,
    :width,
    :height,
    :author_name,
    :author_url,
    :provider_name,
    :provider_url,
    :html,
    :favicon_url
  ]

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, @attrs)
    |> cast_embed(:metadata, with: &metadata_changeset/2)
    |> ensure_url(:resource)
    |> maybe_add_published_at()
    |> validate_resource_or_folder()
    |> validate_required(@required_attrs)
    |> unique_constraint(:url, name: :resource_url_index)
  end

  defp metadata_changeset(schema, params) do
    schema
    |> cast(params, @metadata_attrs)
  end

  @spec validate_resource_or_folder(Changeset.t()) :: Changeset.t()
  defp validate_resource_or_folder(%Changeset{} = changeset) do
    with {status, type} when status in [:changes, :data] <- fetch_field(changeset, :type),
         true <- type != :folder do
      validate_required(changeset, [:resource_url])
    else
      _ -> changeset
    end
  end
end
