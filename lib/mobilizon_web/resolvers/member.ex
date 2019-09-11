defmodule MobilizonWeb.Resolvers.Member do
  @moduledoc """
  Handles the member-related GraphQL calls
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor}

  @doc """
  Find members for group
  """
  def find_members_for_group(%Actor{} = actor, _args, _resolution) do
    members = Actors.list_members_for_group(actor)
    {:ok, members}
  end
end
