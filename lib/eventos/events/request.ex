defmodule Eventos.Events.Request do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Request, Event}
  alias Eventos.Accounts.Account

  schema "event_requests" do
    field :state, :integer
    belongs_to :event, Event
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%Request{} = request, attrs) do
    request
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end
