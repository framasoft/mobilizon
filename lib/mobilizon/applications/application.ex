defmodule Mobilizon.Applications.Application do
  @moduledoc """
  Module representing an application
  """

  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs [:name, :client_id, :client_secret, :redirect_uris, :scope]
  @optional_attrs [:website, :owner_type, :owner_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "applications" do
    field(:name, :string)
    field(:client_id, :string)
    field(:client_secret, :string)
    field(:redirect_uris, {:array, :string})
    field(:scope, :string)
    field(:website, :string)
    field(:owner_type, :string)
    field(:owner_id, :integer)

    timestamps()
  end

  @doc false
  def changeset(application, attrs) do
    application
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
