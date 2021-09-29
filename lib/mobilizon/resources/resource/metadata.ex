defmodule Mobilizon.Resources.Resource.Metadata do
  @moduledoc """
  Represents a resource metadata
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          type: String.t(),
          title: String.t(),
          image_remote_url: String.t(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          author_name: String.t(),
          author_url: String.t(),
          provider_name: String.t(),
          provider_url: String.t(),
          html: String.t(),
          favicon_url: String.t()
        }

  @required_attrs []

  @optional_attrs [
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

  @attrs @required_attrs ++ @optional_attrs

  @primary_key false
  embedded_schema do
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

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
  end
end
