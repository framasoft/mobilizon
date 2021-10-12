defmodule Mobilizon.Federation.ActivityPub.Permission do
  @moduledoc """
  Module to check group members permissions on objects
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.{Entity, Ownable}
  require Logger

  use StructAccess
  defstruct [:access, :create, :update, :delete]

  @member_roles [:member, :moderator, :administrator]

  @type object :: %{id: String.t(), url: String.t()}

  @type permissions_member_role :: nil | :member | :moderator | :administrator

  @type t :: %__MODULE__{
          access: permissions_member_role,
          create: permissions_member_role,
          update: permissions_member_role,
          delete: permissions_member_role
        }

  @doc """
  Check that actor can access the object
  """
  @spec can_access_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_access_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:access, actor, object)
  end

  @doc """
  Check that actor can create such an object
  """
  @spec can_create_group_object?(String.t() | integer(), String.t() | integer(), struct()) ::
          boolean()
  def can_create_group_object?(
        actor_id,
        group_id,
        object
      ) do
    case object |> Ownable.permissions() |> get_in([:create]) do
      :member ->
        Actors.is_member?(actor_id, group_id)

      :moderator ->
        Actors.is_moderator?(actor_id, group_id)

      :administrator ->
        Actors.is_administrator?(actor_id, group_id)

      _ ->
        false
    end
  end

  @doc """
  Check that actor can update the object
  """
  @spec can_update_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_update_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:update, actor, object)
  end

  @doc """
  Check that actor can delete the object
  """
  @spec can_delete_group_object?(Actor.t(), Entity.t()) :: boolean()
  def can_delete_group_object?(%Actor{} = actor, object) do
    can_manage_group_object?(:delete, actor, object)
  end

  @type existing_object_permissions :: :access | :update | :delete

  @spec can_manage_group_object?(
          existing_object_permissions(),
          %Actor{url: String.t()},
          object()
        ) :: boolean()
  defp can_manage_group_object?(permission, %Actor{url: actor_url} = actor, object) do
    if Ownable.group_actor(object) != nil do
      case object |> Ownable.permissions() |> get_in([permission]) do
        role when role in @member_roles ->
          activity_actor_is_group_member?(actor, object, role)

        _ ->
          case permission do
            :access ->
              Logger.warn("Actor #{actor_url} can't access #{object.url}")

            :update ->
              Logger.warn("Actor #{actor_url} can't update #{object.url}")

            :delete ->
              Logger.warn("Actor #{actor_url} can't delete #{object.url}")
          end

          false
      end
    else
      true
    end
  end

  @spec activity_actor_is_group_member?(Actor.t(), object(), atom()) :: boolean()
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
