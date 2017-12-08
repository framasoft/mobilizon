defmodule Eventos.Events.EventRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{EventRequest, Event}
  alias Eventos.Accounts.Account


  schema "event_requests" do
    field :state, :integer
    has_one :event_id, Event
    has_one :account_id, Account

    timestamps()
  end

  @doc false
  def changeset(%EventRequest{} = event_request, attrs) do
    event_request
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end
