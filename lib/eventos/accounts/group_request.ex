defmodule Eventos.Accounts.GroupRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Accounts.{GroupRequest}

  schema "group_requests" do
    field :state, :integer
    field :group_id, :integer
    field :account_id, :integer

    timestamps()
  end

  @doc false
  def changeset(%GroupRequest{} = group_request, attrs) do
    group_request
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end
