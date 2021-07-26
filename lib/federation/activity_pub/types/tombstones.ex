defmodule Mobilizon.Federation.ActivityPub.Types.Tombstones do
  @moduledoc false
  alias Mobilizon.{Actors, Tombstone}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Permission

  def actor(%Tombstone{actor: %Actor{id: actor_id}}), do: Actors.get_actor(actor_id)

  def actor(%Tombstone{actor_id: actor_id}) when not is_nil(actor_id),
    do: Actors.get_actor(actor_id)

  def actor(_), do: nil

  def group_actor(_), do: nil

  def permissions(_) do
    %Permission{access: nil, create: nil, update: nil, delete: nil}
  end
end
