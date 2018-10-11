defmodule Mobilizon.Actors.User do
  @moduledoc """
  Represents a local user
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.{Actor, User}

  schema "users" do
    field(:email, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:role, :integer, default: 0)
    has_many(:actors, Actor)
    field(:confirmed_at, :utc_datetime)
    field(:confirmation_sent_at, :utc_datetime)
    field(:confirmation_token, :string)
    field(:reset_password_sent_at, :utc_datetime)
    field(:reset_password_token, :string)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :role,
      :password_hash,
      :confirmed_at,
      :confirmation_sent_at,
      :confirmation_token,
      :reset_password_sent_at,
      :reset_password_token
    ])
    |> validate_required([:email])
    |> unique_constraint(:email, message: "registration.error.email_already_used")
    |> validate_format(:email, ~r/@/)
    |> validate_length(
      :password,
      min: 6,
      max: 100,
      message: "registration.error.password_too_short"
    )
  end

  def registration_changeset(struct, params) do
    struct
    |> changeset(params)
    |> cast(params, ~w(password)a, [])
    |> validate_required([:email, :password])
    |> validate_length(
      :password,
      min: 6,
      max: 100,
      message: "registration.error.password_too_short"
    )
    |> hash_password()
    |> save_confirmation_token()
    |> unique_constraint(
      :confirmation_token,
      message: "regisration.error.confirmation_token_already_in_use"
    )
  end

  def send_password_reset_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:reset_password_token, :reset_password_sent_at])
  end

  def password_reset_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password, :reset_password_token, :reset_password_sent_at])
    |> validate_length(
      :password,
      min: 6,
      max: 100,
      message: "registration.error.password_too_short"
    )
    |> hash_password()
  end

  defp save_confirmation_token(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: _email}} ->
        changeset = put_change(changeset, :confirmation_token, random_string(30))
        put_change(changeset, :confirmation_sent_at, DateTime.utc_now())

      _ ->
        changeset
    end
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end

  @doc """
  Hash password when it's changed
  """
  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(
          changeset,
          :password_hash,
          Comeonin.Argon2.hashpwsalt(password)
        )

      _ ->
        changeset
    end
  end

  def is_confirmed(%User{confirmed_at: nil} = _user) do
    {:error, :unconfirmed}
  end

  def is_confirmed(%User{} = user) do
    {:ok, user}
  end
end
