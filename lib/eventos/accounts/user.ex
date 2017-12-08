defmodule Eventos.Accounts.User do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{User}


  schema "users" do
    field :email, :string
    field :role, :integer, default: 0
    field :username, :string
    field :account_id, :integer

    coherence_schema()

    timestamps()
  end

  def changeset(user, attrs, :password) do
    user
    |> cast(attrs, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(attrs)
  end

  def changeset(user, attrs, :registration) do
    user
    |> cast(attrs, [:username, :email] ++ coherence_fields())
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username)
    |> validate_coherence(attrs)
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password_hash, :role] ++ coherence_fields())
    |> validate_required([:username, :email])
    |> unique_constraint(:username)
    |> validate_format(:email, ~r/@/)
    |> validate_coherence(attrs)
  end
end
