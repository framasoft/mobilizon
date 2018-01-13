defmodule Eventos.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{Account, User}


  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :role, :integer, default: 0
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :role, :password_hash, :account_id])
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end

  def registration_changeset(struct, params) do
    struct
    |> changeset(params)
    |> cast(params, ~w(password)a, [])
    |> validate_length(:password, min: 6, max: 100)
    |> hash_password
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true,
        changes: %{password: password}} ->
        put_change(changeset,
          :password_hash,
          Comeonin.Argon2.hashpwsalt(password))
      _ ->
        changeset
    end
  end

end
