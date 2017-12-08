defmodule Eventos.Events.EventAccounts do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{EventAccounts, Event}
  alias Eventos.Accounts.Account

  @primary_key false
  schema "event_accounts" do
    field :roles, :integer
    belongs_to :event, Event
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%EventAccounts{} = event_accounts, attrs) do
    event_accounts
    |> cast(attrs, [:roles])
    |> validate_required([:roles])
  end
end
