defmodule Eventos.Accounts.Account do
  @moduledoc """
  Represents an account (local and remote users)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts
  alias Eventos.Accounts.{Account, User}
  alias Eventos.Groups.{Group, Member, Request}
  alias Eventos.Events.Event
  alias Eventos.Service.ActivityPub

  import Logger

  @type t :: %Account{description: String.t, id: integer(), inserted_at: DateTime.t, updated_at: DateTime.t, display_name: String.t, domain: String.t, private_key: String.t, public_key: String.t, suspended: boolean(), url: String.t, username: String.t, organized_events: list(), groups: list(), group_request: list(), user: User.t}

  schema "accounts" do
    field :description, :string
    field :display_name, :string
    field :domain, :string
    field :private_key, :string
    field :public_key, :string
    field :suspended, :boolean, default: false
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
    |> cast(attrs, [:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :url])
    |> validate_required([:username, :public_key, :suspended, :url])
    |> unique_constraint(:username, name: :accounts_username_domain_index)
  end

  def registration_changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :url])
    |> validate_required([:username, :public_key, :suspended, :url])
    |> unique_constraint(:username)
  end

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  def remote_account_creation(params) do
    changes =
      %Account{}
      |> cast(params, [:description, :display_name, :url, :username, :public_key])
      |> validate_required([:url, :username, :public_key])
      |> unique_constraint(:username)
      |> validate_format(:username, @email_regex)
      |> validate_length(:description, max: 5000)
      |> validate_length(:display_name, max: 100)
      |> put_change(:local, false)

    Logger.debug("Remote account creation")
    Logger.debug(inspect changes)
    changes
    #    if changes.valid? do
    #      case changes.changes[:info]["source_data"] do
    #        %{"followers" => followers} ->
    #          changes
    #          |> put_change(:follower_address, followers)
    #
    #        _ ->
    #          followers = User.ap_followers(%User{nickname: changes.changes[:nickname]})
    #
    #          changes
    #          |> put_change(:follower_address, followers)
    #      end
    #    else
    #      changes
    #    end
  end

  def get_or_fetch_by_url(url) do
    if user = Accounts.get_account_by_url(url) do
      user
    else
      case ActivityPub.make_account_from_url(url) do
        {:ok, user} ->
          user
        _ -> {:error, "Could not fetch by AP id"}
      end
    end
  end

  @spec get_public_key_for_url(Account.t) :: {:ok, String.t}
  def get_public_key_for_url(url) do
    with %Account{} = account <- get_or_fetch_by_url(url) do
      get_public_key_for_account(account)
    else
      _ -> :error
    end
  end

  @spec get_public_key_for_account(Account.t) :: {:ok, String.t}
  def get_public_key_for_account(%Account{} = account) do
    {:ok, account.public_key}
  end

  @spec get_private_key_for_account(Account.t) :: {:ok, String.t}
  def get_private_key_for_account(%Account{} = account) do
    account.private_key
  end
end
