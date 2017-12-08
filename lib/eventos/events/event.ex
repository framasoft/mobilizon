defmodule Eventos.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Event, EventAccount, EventRequest}
  alias Eventos.Accounts.Account


  schema "events" do
    field :begin_on, :utc_datetime
    field :description, :string
    field :ends_on, :utc_datetime
    field :title, :string
    has_one :organizer_id, Account
    many_to_many :participants, Account, join_through: EventAccount
    has_many :event_request, EventRequest

    timestamps()
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:title, :description, :begin_on, :ends_on])
    |> validate_required([:title, :description, :begin_on, :ends_on, :organizer_id])
  end
end
