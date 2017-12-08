defmodule Eventos.Accounts.Group do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{Group, Account, GroupAccount, GroupRequest}


  schema "groups" do
    field :description, :string
    field :suspended, :boolean, default: false
    field :title, :string
    field :uri, :string
    field :url, :string
    many_to_many :accounts, Account, join_through: GroupAccount
    has_many :requests, GroupRequest

    timestamps()
  end

  @doc false
  def changeset(%Group{} = group, attrs) do
    group
    |> cast(attrs, [:title, :description, :suspended, :url, :uri])
    |> validate_required([:title, :description, :suspended, :url, :uri])
  end
end
