defmodule Mobilizon.Federation.ActivityPub.Types.Resources do
  @moduledoc false
  alias Mobilizon.{Actors, Resources}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Permission
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Service.Activity.Resource, as: ResourceActivity
  alias Mobilizon.Service.RichMedia.Parser
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [make_create_data: 2, make_update_data: 2, make_add_data: 3, make_move_data: 4]

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Resource.t(), ActivityStream.t()}
          | {:error, Ecto.Changeset.t() | :creator_not_found | :group_not_found}
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
         {:ok, %Actor{} = group, %Actor{url: creator_url} = creator} <-
           group_and_creator(group_id, creator_id) do
      ResourceActivity.insert_activity(resource, subject: "resource_created")
      resource_as_data = Convertible.model_to_as(%{resource | actor: group, creator: creator})

      audience = %{
        "to" => [group.members_url],
        "cc" => [],
        "actor" => creator_url,
        "attributedTo" => [creator_url]
      }

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
    end
  end

  @impl Entity
  @spec update(Resource.t(), map(), map()) ::
          {:ok, Resource.t(), ActivityStream.t()}
          | {:error, Ecto.Changeset.t() | :creator_not_found | :group_not_found}
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
         {:ok, %Actor{} = group, %Actor{url: creator_url}} <-
           group_and_creator(group_id, creator_id) do
      ResourceActivity.insert_activity(resource,
        subject: "resource_renamed",
        old_resource: old_resource
      )

      resource_as_data = Convertible.model_to_as(%{resource | actor: group})

      audience = %{
        "to" => [group.members_url],
        "cc" => [],
        "actor" => creator_url,
        "attributedTo" => [creator_url]
      }

      update_data = make_update_data(resource_as_data, Map.merge(audience, additional))
      {:ok, resource, update_data}
    end
  end

  @spec move(Resource.t(), map(), map()) ::
          {:ok, Resource.t(), ActivityStream.t()}
          | {:error,
             Ecto.Changeset.t()
             | :creator_not_found
             | :group_not_found
             | :new_parent_not_found
             | :old_parent_not_found}
  def move(
        %Resource{parent_id: old_parent_id} = old_resource,
        %{parent_id: _new_parent_id} = args,
        additional
      ) do
    with {:ok,
          %Resource{actor_id: group_id, creator_id: creator_id, parent_id: new_parent_id} =
            resource} <-
           Resources.update_resource(old_resource, args),
         {:ok, old_parent, new_parent} <- parents(old_parent_id, new_parent_id),
         {:ok, %Actor{} = group, %Actor{url: creator_url}} <-
           group_and_creator(group_id, creator_id) do
      ResourceActivity.insert_activity(resource, subject: "resource_moved")
      resource_as_data = Convertible.model_to_as(%{resource | actor: group})

      audience = %{
        "to" => [group.members_url],
        "cc" => [],
        "actor" => creator_url,
        "attributedTo" => [creator_url]
      }

      move_data =
        make_move_data(
          resource_as_data,
          old_parent,
          new_parent,
          Map.merge(audience, additional)
        )

      {:ok, resource, move_data}
    end
  end

  @impl Entity
  @spec delete(Resource.t(), Actor.t(), boolean, map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Resource.t()} | {:error, Ecto.Changeset.t()}
  def delete(
        %Resource{url: url, type: type, actor: %Actor{url: group_url, members_url: members_url}} =
          resource,
        %Actor{url: actor_url} = actor,
        _local,
        _additionnal
      ) do
    Logger.debug("Building Delete Resource activity")

    activity_data = %{
      "actor" => actor_url,
      "attributedTo" => [group_url],
      "type" => "Delete",
      "object" => %{
        "type" => "Tombstone",
        "formerType" => if(type == :folder, do: "ResourceCollection", else: "Document"),
        "deleted" => DateTime.utc_now(),
        "id" => url
      },
      "id" => url <> "/delete",
      "to" => [members_url]
    }

    case Resources.delete_resource(resource) do
      {:ok, _resource} ->
        ResourceActivity.insert_activity(resource, subject: "resource_deleted")
        Cachex.del(:activity_pub, "resource_#{resource.id}")
        {:ok, activity_data, actor, resource}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(Todo.t()) :: Actor.t() | nil
  def actor(%Resource{creator_id: creator_id}),
    do: Actors.get_actor(creator_id)

  @spec group_actor(Todo.t()) :: Actor.t() | nil
  def group_actor(%Resource{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  @spec permissions(TodoList.t()) :: Permission.t()
  def permissions(%Resource{}) do
    %Permission{access: :member, create: :member, update: :member, delete: :member}
  end

  @spec group_and_creator(integer(), integer()) ::
          {:ok, Actor.t(), Actor.t()} | {:error, :creator_not_found | :group_not_found}
  defp group_and_creator(group_id, creator_id) do
    case Actors.get_group_by_actor_id(group_id) do
      {:ok, %Actor{} = group} ->
        case Actors.get_actor(creator_id) do
          %Actor{} = creator ->
            {:ok, group, creator}

          nil ->
            {:error, :creator_not_found}
        end

      {:error, :group_not_found} ->
        {:error, :group_not_found}
    end
  end

  @spec parents(String.t(), String.t()) ::
          {:ok, Resource.t(), Resource.t()}
  defp parents(old_parent_id, new_parent_id) do
    {:ok, Resources.get_resource(old_parent_id), Resources.get_resource(new_parent_id)}
  end
end
