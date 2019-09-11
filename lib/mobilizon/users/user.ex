defmodule Mobilizon.Users.User do
  @moduledoc """
  Represents a local user.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Crypto
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Service.EmailChecker
  alias Mobilizon.Users.{User, UserRole}

  @type t :: %__MODULE__{
          email: String.t(),
          password_hash: String.t(),
          password: String.t(),
          role: UserRole.t(),
          confirmed_at: DateTime.t(),
          confirmation_sent_at: DateTime.t(),
          confirmation_token: String.t(),
          reset_password_sent_at: DateTime.t(),
          reset_password_token: String.t(),
          default_actor: Actor.t(),
          actors: [Actor.t()],
          feed_tokens: [FeedToken.t()]
        }

  @required_attrs [:email]
  @optional_attrs [
    :role,
    :password,
    :password_hash,
    :confirmed_at,
    :confirmation_sent_at,
    :confirmation_token,
    :reset_password_sent_at,
    :reset_password_token
  ]
  @attrs @required_attrs ++ @optional_attrs

  @registration_required_attrs [:email, :password]

  @password_reset_required_attrs [:password, :reset_password_token, :reset_password_sent_at]

  @confirmation_token_length 30

  schema "users" do
    field(:email, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:role, UserRole, default: :user)
    field(:confirmed_at, :utc_datetime)
    field(:confirmation_sent_at, :utc_datetime)
    field(:confirmation_token, :string)
    field(:reset_password_sent_at, :utc_datetime)
    field(:reset_password_token, :string)

    belongs_to(:default_actor, Actor)
    has_many(:actors, Actor)
    has_many(:feed_tokens, FeedToken, foreign_key: :user_id)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(%User{} = user, attrs) do
    changeset =
      user
      |> cast(attrs, @attrs)
      |> validate_required(@required_attrs)
      |> unique_constraint(:email, message: "This email is already used.")
      |> validate_email()
      |> validate_length(:password, min: 6, max: 100, message: "The chosen password is too short.")

    if Map.has_key?(attrs, :default_actor) do
      put_assoc(changeset, :default_actor, attrs.default_actor)
    else
      changeset
    end
  end

  @doc false
  @spec registration_changeset(User.t(), map) :: Ecto.Changeset.t()
  def registration_changeset(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> cast_assoc(:default_actor)
    |> validate_required(@registration_required_attrs)
    |> hash_password()
    |> save_confirmation_token()
    |> unique_constraint(
      :confirmation_token,
      message: "The registration is already in use, this looks like an issue on our side."
    )
  end

  @doc false
  @spec send_password_reset_changeset(User.t(), map) :: Ecto.Changeset.t()
  def send_password_reset_changeset(%User{} = user, attrs) do
    cast(user, attrs, [:reset_password_token, :reset_password_sent_at])
  end

  @doc false
  @spec password_reset_changeset(User.t(), map) :: Ecto.Changeset.t()
  def password_reset_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @password_reset_required_attrs)
    |> validate_length(:password,
      min: 6,
      max: 100,
      message: "registration.error.password_too_short"
    )
    |> hash_password()
  end

  @doc """
  Checks whether an user is confirmed. 
  """
  @spec is_confirmed(User.t()) :: boolean
  def is_confirmed(%User{confirmed_at: nil}), do: false
  def is_confirmed(%User{}), do: true

  @doc """
  Returns whether an user owns an actor.
  """
  @spec owns_actor(User.t(), integer | String.t()) :: {:is_owned, Actor.t() | nil}
  def owns_actor(%User{actors: actors}, actor_id) do
    user_actor = Enum.find(actors, fn actor -> "#{actor.id}" == "#{actor_id}" end)

    {:is_owned, user_actor}
  end

  @spec save_confirmation_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp save_confirmation_token(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: _email}} ->
        now = DateTime.utc_now()

        changeset
        |> put_change(:confirmation_token, Crypto.random_string(@confirmation_token_length))
        |> put_change(:confirmation_sent_at, DateTime.truncate(now, :second))

      _ ->
        changeset
    end
  end

  @spec validate_email(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_email(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: email}} ->
        case EmailChecker.valid?(email) do
          false ->
            add_error(changeset, :email, "Email doesn't fit required format")

          true ->
            changeset
        end

      _ ->
        changeset
    end
  end

  @spec hash_password(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
