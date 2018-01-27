defmodule Eventos.Events.Participant do
  @moduledoc """
  Represents a participant, an account participating to an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Participant, Event}
  alias Eventos.Accounts.Account

  @primary_key false
  schema "participants" do
    field :role, :integer, default: 0
    belongs_to :event, Event, primary_key: true
    belongs_to :account, Account, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> cast(attrs, [:role, :event_id, :account_id])
    |> validate_required([:event_id, :account_id])
  end
end
