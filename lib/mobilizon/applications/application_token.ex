defmodule Mobilizon.Applications.ApplicationToken do
  @moduledoc """
  Module representing an application token
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Applications.{Application, ApplicationTokenStatus}
  alias Mobilizon.Users.User

  schema "application_tokens" do
    belongs_to(:user, User)
    belongs_to(:application, Application)
    field(:authorization_code, :string)
    field(:status, ApplicationTokenStatus, default: :pending)
    field(:scope, :string)

    timestamps()
  end

  @required_attrs [:user_id, :application_id, :scope]
  @optional_attrs [:authorization_code, :status]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(application_token, attrs) do
    application_token
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
