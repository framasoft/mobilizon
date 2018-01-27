defmodule Eventos.Accounts.Account do
  @moduledoc """
  Represents an account (local and remote users)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{Account, User}
  alias Eventos.Groups.{Group, Member, Request}
  alias Eventos.Events.Event

  schema "accounts" do
    field :description, :string
    field :display_name, :string
    field :domain, :string
    field :private_key, :string
    field :public_key, :string
    field :suspended, :boolean, default: false
    field :uri, :string
    field :url, :string
    field :username, :string
    field :avatar_url, :string
    field :banner_url, :string
    has_many :organized_events, Event, [foreign_key: :organizer_account_id]
    many_to_many :groups, Group, join_through: Member
    has_many :group_request, Request
    has_one :user, User

    timestamps()
  end

  @doc false
  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :uri, :url, :avatar_url, :banner_url])
    |> validate_required([:username, :public_key, :suspended, :uri, :url])
    |> unique_constraint(:username, name: :accounts_username_domain_index)
  end

  def registration_changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :uri, :url, :avatar_url, :banner_url])
    |> validate_required([:username, :public_key, :suspended, :uri, :url])
    |> unique_constraint(:username)
  end
end
