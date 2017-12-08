defmodule Eventos.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{Account, GroupAccount, GroupRequest, Group, User}
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
    has_many :organized_events, Event
    many_to_many :groups, Group, join_through: GroupAccount
    has_many :group_request, GroupRequest
    has_one :user_id, User

    timestamps()
  end

  @doc false
  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :uri, :url])
    |> validate_required([:username, :domain, :display_name, :description, :private_key, :public_key, :suspended, :uri, :url])
  end
end
