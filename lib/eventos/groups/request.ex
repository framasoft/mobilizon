defmodule Eventos.Groups.Request do
  @moduledoc """
  Represents a group request, when an user wants to be member of a group
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Groups.Request


  schema "group_requests" do
    field :state, :integer
    field :group_id, :integer
    field :account_id, :integer

    timestamps()
  end

  @doc false
  def changeset(%Request{} = request, attrs) do
    request
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end
