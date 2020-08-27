defmodule Mobilizon.Federation.ActivityPub.Types.Members do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityStream.Convertible
  require Logger
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_update_data: 2]

  def update(
        %Member{parent: %Actor{id: group_id}, id: member_id, role: current_role} = member,
        %{role: updated_role} = args,
        %{moderator: %Actor{url: moderator_url, id: moderator_id}} = additional
      ) do
    with additional <- Map.delete(additional, :moderator),
         {:has_rights_to_update_role, {:ok, %Member{role: moderator_role}}}
         when moderator_role in [:moderator, :administrator, :creator] <-
           {:has_rights_to_update_role, Actors.get_member(moderator_id, group_id)},
         {:is_only_admin, false} <-
           {:is_only_admin, check_admins_left(member_id, group_id, current_role, updated_role)},
         {:ok, %Member{} = member} <-
           Actors.update_member(member, args),
         {:ok, true} <- Cachex.del(:activity_pub, "member_#{member_id}"),
         member_as_data <-
           Convertible.model_to_as(member),
         audience <- %{
           "to" => [member.parent.members_url, member.actor.url],
           "cc" => [member.parent.url],
           "actor" => moderator_url,
           "attributedTo" => [member.parent.url]
         } do
      update_data = make_update_data(member_as_data, Map.merge(audience, additional))

      {:ok, member, update_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  # Used only when a group is suspended
  def delete(
        %Member{parent: %Actor{} = group, actor: %Actor{} = actor} = _member,
        %Actor{},
        local,
        _additionnal
      ) do
    Logger.debug("Deleting a member")
    ActivityPub.leave(group, actor, local, %{force_member_removal: true})
  end

  def actor(%Member{actor_id: actor_id}),
    do: Actors.get_actor(actor_id)

  def group_actor(%Member{parent_id: parent_id}),
    do: Actors.get_actor(parent_id)

  defp check_admins_left(member_id, group_id, current_role, updated_role) do
    Actors.is_only_administrator?(member_id, group_id) && current_role == :administrator &&
      updated_role != :administrator
  end
end
