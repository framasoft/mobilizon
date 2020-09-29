defmodule Mobilizon.Users.User do
  @moduledoc """
  Represents a local user.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Crypto
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Users.{Setting, UserRole}
  alias Mobilizon.Web.Email.Checker
  import Mobilizon.Web.Gettext

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
          locale: String.t(),
          default_actor: Actor.t(),
          disabled: boolean(),
          actors: [Actor.t()],
          feed_tokens: [FeedToken.t()],
          last_sign_in_at: DateTime.t(),
          last_sign_in_ip: String.t(),
          current_sign_in_ip: String.t(),
          current_sign_in_at: DateTime.t()
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
    :reset_password_token,
    :default_actor_id,
    :locale,
    :unconfirmed_email,
    :disabled,
    :provider,
    :last_sign_in_at,
    :last_sign_in_ip,
    :current_sign_in_ip,
    :current_sign_in_at
  ]
  @attrs @required_attrs ++ @optional_attrs

  @registration_required_attrs @required_attrs ++ [:password]

  @auth_provider_required_attrs @required_attrs ++ [:provider]

  @password_change_required_attrs [:password]
  @password_reset_required_attrs @password_change_required_attrs ++
                                   [:reset_password_token, :reset_password_sent_at]

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
    field(:unconfirmed_email, :string)
    field(:locale, :string, default: "en")
    field(:disabled, :boolean, default: false)
    field(:provider, :string)
    field(:last_sign_in_at, :utc_datetime)
    field(:last_sign_in_ip, :string)
    field(:current_sign_in_ip, :string)
    field(:current_sign_in_at, :utc_datetime)

    belongs_to(:default_actor, Actor)
    has_many(:actors, Actor)
    has_many(:feed_tokens, FeedToken, foreign_key: :user_id)
    has_one(:settings, Setting)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = user, attrs) do
    changeset =
      user
      |> cast(attrs, @attrs)
      |> validate_required(@required_attrs)
      |> unique_constraint(:email, message: dgettext("errors", "This email is already used."))
      |> Checker.validate_changeset()
      |> validate_length(:password,
        min: 6,
        max: 200,
        message: dgettext("errors", "The chosen password is too short.")
      )

    if Map.has_key?(attrs, :default_actor) do
      put_assoc(changeset, :default_actor, attrs.default_actor)
    else
      changeset
    end
  end

  def delete_changeset(%__MODULE__{} = user) do
    user
    |> change()
    |> put_change(:disabled, true)
    |> put_change(:default_actor_id, nil)
  end

  @doc false
  @spec registration_changeset(t, map) :: Ecto.Changeset.t()
  def registration_changeset(%__MODULE__{} = user, attrs) do
    user
    |> changeset(attrs)
    |> cast_assoc(:default_actor)
    |> validate_required(@registration_required_attrs)
    |> hash_password()
    |> save_confirmation_token()
    |> unique_constraint(
      :confirmation_token,
      message:
        dgettext(
          "errors",
          "The registration token is already in use, this looks like an issue on our side."
        )
    )
  end

  @doc false
  @spec auth_provider_changeset(t, map) :: Ecto.Changeset.t()
  def auth_provider_changeset(%__MODULE__{} = user, attrs) do
    user
    |> changeset(attrs)
    |> cast_assoc(:default_actor)
    |> put_change(:confirmed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_required(@auth_provider_required_attrs)
  end

  @doc false
  @spec send_password_reset_changeset(t, map) :: Ecto.Changeset.t()
  def send_password_reset_changeset(%__MODULE__{} = user, attrs) do
    cast(user, attrs, [:reset_password_token, :reset_password_sent_at])
  end

  @doc false
  @spec password_reset_changeset(t, map) :: Ecto.Changeset.t()
  def password_reset_changeset(%__MODULE__{} = user, attrs) do
    password_change_changeset(user, attrs, @password_reset_required_attrs)
  end

  @doc """
  Changeset to change a password

  It checks the minimum requirements for a password and hashes it.
  """
  @spec password_change_changeset(t, map) :: Ecto.Changeset.t()
  def password_change_changeset(
        %__MODULE__{} = user,
        attrs,
        required_attrs \\ @password_change_required_attrs
      ) do
    user
    |> cast(attrs, required_attrs)
    |> validate_length(:password,
      min: 6,
      max: 200,
      message: "registration.error.password_too_short"
    )
    |> hash_password()
  end

  @doc """
  Checks whether an user is confirmed.
  """
  @spec is_confirmed(t) :: boolean
  def is_confirmed(%__MODULE__{confirmed_at: nil}), do: false
  def is_confirmed(%__MODULE__{}), do: true

  @doc """
  Returns whether an user owns an actor.
  """
  @spec owns_actor(t, integer | String.t()) :: {:is_owned, Actor.t() | nil}
  def owns_actor(%__MODULE__{actors: actors}, actor_id) do
    user_actor = Enum.find(actors, fn actor -> "#{actor.id}" == "#{actor_id}" end)

    {:is_owned, user_actor}
  end

  @spec save_confirmation_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp save_confirmation_token(
         %Ecto.Changeset{valid?: true, changes: %{email: _email}} = changeset
       ) do
    case fetch_change(changeset, :confirmed_at) do
      :error ->
        changeset
        |> put_change(:confirmation_token, Crypto.random_string(@confirmation_token_length))
        |> put_change(:confirmation_sent_at, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end

  defp save_confirmation_token(%Ecto.Changeset{} = changeset), do: changeset

  @spec hash_password(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp hash_password(%Ecto.Changeset{} = changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
