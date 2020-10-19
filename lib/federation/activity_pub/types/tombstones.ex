defmodule Mobilizon.Federation.ActivityPub.Types.Tombstones do
  @moduledoc false
  alias Mobilizon.{Actors, Tombstone}
  alias Mobilizon.Actors.Actor

  def actor(%Tombstone{actor: %Actor{id: actor_id}}), do: Actors.get_actor(actor_id)

  def actor(%Tombstone{actor_id: actor_id}) when not is_nil(actor_id),
    do: Actors.get_actor(actor_id)

  def actor(_), do: nil

  def group_actor(_), do: nil

  def role_needed_to_update(%Actor{}), do: nil
  def role_needed_to_delete(%Actor{}), do: nil
end
