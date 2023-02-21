defmodule Mobilizon.Applications.ApplicationDeviceActivation do
  @moduledoc """
  Module representing a application device activation
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Applications.{Application, ApplicationDeviceActivationStatus}
  alias Mobilizon.Users.User

  schema "application_device_activation" do
    field(:user_code, :string)
    field(:device_code, :string)
    field(:scope, :string)
    field(:expires_in, :integer)
    field(:status, ApplicationDeviceActivationStatus, default: :pending)
    belongs_to(:user, User)
    belongs_to(:application, Application)

    timestamps()
  end

  @required_attrs [:user_code, :device_code, :expires_in, :application_id]
  @optional_attrs [:status, :user_id]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(application_device_activation, attrs) do
    application_device_activation
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
