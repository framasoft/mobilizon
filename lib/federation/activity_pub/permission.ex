defmodule Mobilizon.Federation.ActivityPub.Permission do
  @moduledoc """
  Module to check group members permissions on objects
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.{Entity, Ownable}
  require Logger

  @doc """
  Check that actor can access the object
  """
  @spec can_access_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_access_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:role_needed_to_access, actor, object)
  end

  @doc """
  Check that actor can update the object
  """
  @spec can_update_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_update_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:role_needed_to_update, actor, object)
  end

  @doc """
  Check that actor can delete the object
  """
  @spec can_delete_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_delete_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:role_needed_to_delete, actor, object)
  end

  @spec can_manage_group_object?(
          :role_needed_to_access | :role_needed_to_update | :role_needed_to_delete,
          Actor.t(),
          any()
        ) :: boolean()
  defp can_manage_group_object?(action_function, %Actor{url: actor_url} = actor, object) do
    if Ownable.group_actor(object) != nil do
      case apply(Ownable, action_function, [object]) do
        role when role in [:member, :moderator, :administrator] ->
          activity_actor_is_group_member?(actor, object, role)

        _ ->
          case action_function do
            :role_needed_to_access ->
              Logger.warn("Actor #{actor_url} can't access #{object.url}")

            :role_needed_to_update ->
              Logger.warn("Actor #{actor_url} can't update #{object.url}")

            :role_needed_to_delete ->
              Logger.warn("Actor #{actor_url} can't delete #{object.url}")
          end

          false
      end
    else
      true
    end
  end

  @spec activity_actor_is_group_member?(Actor.t(), Entity.t(), atom()) :: boolean()
  defp activity_actor_is_group_member?(
         %Actor{id: actor_id, url: actor_url},
         object,
         role
       ) do
    case Ownable.group_actor(object) do
      %Actor{type: :Group, id: group_id, url: group_url} ->
        Logger.debug("Group object url is #{group_url}")

        case role do
          :moderator ->
            Logger.debug(
              "Checking if activity actor #{actor_url} is a moderator from group from #{object.url}"
            )

            Actors.is_moderator?(actor_id, group_id)

          :administrator ->
            Logger.debug(
              "Checking if activity actor #{actor_url} is an administrator from group from #{object.url}"
            )

            Actors.is_administrator?(actor_id, group_id)

          _ ->
            Logger.debug(
              "Checking if activity actor #{actor_url} is a member from group from #{object.url}"
            )

            Actors.is_member?(actor_id, group_id)
        end

      _ ->
        false
    end
  end
end
