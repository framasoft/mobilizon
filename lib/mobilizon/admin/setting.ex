defmodule Mobilizon.Admin.Setting do
  @moduledoc """
  A Key-Value settings table for basic settings
  """
  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs [:group, :name]
  @optional_attrs [:value]
  @attrs @required_attrs ++ @optional_attrs

  schema "admin_settings" do
    field(:group, :string)
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:group, name: :admin_settings_group_name_index)
  end
end
