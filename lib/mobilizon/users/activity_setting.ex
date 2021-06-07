defmodule Mobilizon.Users.ActivitySetting do
  @moduledoc """
  Module to manage users settings
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Users.User

  @type t :: %__MODULE__{
          key: String.t(),
          method: String.t(),
          enabled: boolean()
        }

  @attrs [:key, :method, :enabled, :user_id]

  @primary_key {:user_id, :id, autogenerate: false}
  schema "user_activity_settings" do
    field(:key, :string)
    field(:method, :string)
    field(:enabled, :boolean)

    belongs_to(:user, User, primary_key: true, type: :id, foreign_key: :id, define_field: false)
  end

  @doc false
  def changeset(activity_setting, attrs) do
    activity_setting
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
    |> unique_constraint([:key, :method], name: :user_activity_settings_user_id_key_method_index)
  end
end
