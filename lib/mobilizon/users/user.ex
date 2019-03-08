import EctoEnum

defenum(Mobilizon.Users.UserRoleEnum, :user_role_type, [
  :administrator,
  :moderator,
  :user
])

defmodule Mobilizon.Users.User do
  @moduledoc """
  Represents a local user
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  alias Mobilizon.Service.EmailChecker
  alias Mobilizon.Events.FeedToken

  schema "users" do
    field(:email, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:role, Mobilizon.Users.UserRoleEnum, default: :user)
    has_many(:actors, Actor)
    belongs_to(:default_actor, Actor)
    field(:confirmed_at, :utc_datetime)
    field(:confirmation_sent_at, :utc_datetime)
    field(:confirmation_token, :string)
    field(:reset_password_sent_at, :utc_datetime)
    field(:reset_password_token, :string)
    has_many(:feed_tokens, FeedToken, foreign_key: :user_id)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    changeset =
      user
      |> cast(attrs, [
        :email,
        :role,
        :password,
        :password_hash,
        :confirmed_at,
        :confirmation_sent_at,
        :confirmation_token,
        :reset_password_sent_at,
        :reset_password_token
      ])
      |> validate_required([:email])
      |> unique_constraint(:email, message: "This email is already used.")
      |> validate_email()
      |> validate_length(
        :password,
        min: 6,
        max: 100,
        message: "The chosen password is too short."
      )

    if Map.has_key?(attrs, :default_actor) do
      put_assoc(changeset, :default_actor, attrs.default_actor)
    else
      changeset
    end
  end

  def registration_changeset(struct, params) do
    struct
    |> changeset(params)
    |> cast_assoc(:default_actor)
    |> validate_required([:email, :password])
    |> hash_password()
    |> save_confirmation_token()
    |> unique_constraint(
      :confirmation_token,
      message: "The registration is already in use, this looks like an issue on our side."
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

        put_change(
          changeset,
          :confirmation_sent_at,
          DateTime.utc_now() |> DateTime.truncate(:second)
        )

      _ ->
        changeset
    end
  end

  defp validate_email(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: email}} ->
        case EmailChecker.valid?(email) do
          false -> add_error(changeset, :email, "Email doesn't fit required format")
          _ -> changeset
        end

      _ ->
        changeset
    end
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end

  # Hash password when it's changed
  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(
          changeset,
          :password_hash,
          Argon2.hash_pwd_salt(password)
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

  def owns_actor(%User{actors: actors}, actor_id) do
    case Enum.find(actors, fn a -> a.id == actor_id end) do
      nil -> {:is_owned, false}
      actor -> {:is_owned, true, actor}
    end
  end
end
