defmodule Mobilizon.Federation.ActivityPub.Types.Resources do
  @moduledoc false
  alias Mobilizon.{Actors, Resources}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Service.Activity.Resource, as: ResourceActivity
  alias Mobilizon.Service.RichMedia.Parser
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [make_create_data: 2, make_update_data: 2, make_add_data: 3, make_move_data: 4]

  @behaviour Entity

  @impl Entity
  def create(%{type: type} = args, additional) do
    args =
      case type do
        :folder ->
          args

        _ ->
          case Parser.parse(Map.get(args, :resource_url)) do
            {:ok, metadata} ->
              Map.put(args, :metadata, metadata)

            _ ->
              args
          end
      end

    with {:ok,
          %Resource{actor_id: group_id, creator_id: creator_id, parent_id: parent_id} = resource} <-
           Resources.create_resource(args),
         {:ok, _} <- ResourceActivity.insert_activity(resource, subject: "resource_created"),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} = creator <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group, creator: creator}),
         audience <- %{
           "to" => [group.members_url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         } do
      create_data =
        case parent_id do
          nil ->
            make_create_data(resource_as_data, Map.merge(audience, additional))

          parent_id ->
            # In case the resource has a parent we don't `Create` the resource but `Add` it to an existing resource
            parent = Resources.get_resource(parent_id)
            make_add_data(resource_as_data, parent, Map.merge(audience, additional))
        end

      {:ok, resource, create_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  def update(
        %Resource{parent_id: old_parent_id} = old_resource,
        %{parent_id: parent_id} = args,
        additional
      )
      when old_parent_id != parent_id do
    move(old_resource, args, additional)
  end

  # Simple rename
  def update(%Resource{} = old_resource, %{title: title} = _args, additional) do
    with {:ok, %Resource{actor_id: group_id, creator_id: creator_id} = resource} <-
           Resources.update_resource(old_resource, %{title: title}),
         {:ok, _} <-
           ResourceActivity.insert_activity(resource,
             subject: "resource_renamed",
             old_resource: old_resource
           ),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group}),
         audience <- %{
           "to" => [group.members_url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         },
         update_data <-
           make_update_data(resource_as_data, Map.merge(audience, additional)) do
      {:ok, resource, update_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  def move(
        %Resource{parent_id: old_parent_id} = old_resource,
        %{parent_id: _new_parent_id} = args,
        additional
      ) do
    with {:ok,
          %Resource{actor_id: group_id, creator_id: creator_id, parent_id: new_parent_id} =
            resource} <-
           Resources.update_resource(old_resource, args),
         {:ok, _} <- ResourceActivity.insert_activity(resource, subject: "resource_moved"),
         old_parent <- Resources.get_resource(old_parent_id),
         new_parent <- Resources.get_resource(new_parent_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group}),
         audience <- %{
           "to" => [group.members_url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         },
         move_data <-
           make_move_data(
             resource_as_data,
             old_parent,
             new_parent,
             Map.merge(audience, additional)
           ) do
      {:ok, resource, move_data}
    else
      err ->
        Logger.debug(inspect(err))
        err
    end
  end

  @impl Entity
  def delete(
        %Resource{url: url, actor: %Actor{url: group_url, members_url: members_url}} = resource,
        %Actor{url: actor_url} = actor,
        _local,
        _additionnal
      ) do
    Logger.debug("Building Delete Resource activity")

    activity_data = %{
      "actor" => actor_url,
      "attributedTo" => [group_url],
      "type" => "Delete",
      "object" => Convertible.model_to_as(resource),
      "id" => url <> "/delete",
      "to" => [members_url]
    }

    with {:ok, _resource} <- Resources.delete_resource(resource),
         {:ok, _} <- ResourceActivity.insert_activity(resource, subject: "resource_deleted"),
         {:ok, true} <- Cachex.del(:activity_pub, "resource_#{resource.id}") do
      {:ok, activity_data, actor, resource}
    end
  end

  def actor(%Resource{creator_id: creator_id}),
    do: Actors.get_actor(creator_id)

  def group_actor(%Resource{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  def role_needed_to_update(%Resource{}), do: :member
  def role_needed_to_delete(%Resource{}), do: :member
end
