defmodule Eventos.Accounts.GroupAccount do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{GroupAccount, Account, Group}

  @primary_key false
  schema "group_accounts" do
    field :role, :integer
    belongs_to :group, Group
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%GroupAccount{} = group_account, attrs) do
    group_account
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end
end
