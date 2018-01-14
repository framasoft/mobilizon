defmodule Eventos.Groups.Member do
  @moduledoc """
  Represents the membership of an account to a group
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Groups.{Member, Group}
  alias Eventos.Accounts.Account


  schema "members" do
    field :role, :integer
    belongs_to :group, Group
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%Member{} = member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end
end
