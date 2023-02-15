defmodule Mobilizon.Applications.ApplicationToken do
  @moduledoc """
  Module representing an application token
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "application_tokens" do
    belongs_to(:user, Mobilizon.Users.User)
    belongs_to(:application, Mobilizon.Applications.Application)
    field(:authorization_code, :string)

    timestamps()
  end

  @required_attrs [:user_id, :application_id]
  @optional_attrs [:authorization_code]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(application_token, attrs) do
    application_token
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
