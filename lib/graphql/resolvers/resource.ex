defmodule Mobilizon.GraphQL.Resolvers.Resource do
  @moduledoc """
  Handles the resources-related GraphQL calls
  """

  alias Mobilizon.{Actors, Resources, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Resources.Resource.Metadata
  alias Mobilizon.Service.RichMedia.Parser
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  alias Mobilizon.Web.MediaProxy
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find resources for group.

  Returns only if actor requesting is a member of the group
  """
  def find_resources_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit},
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         %Page{} = page <- Resources.get_resources_for_group(group, page, limit) do
      {:ok, page}
    else
      {:member, _} ->
        find_resources_for_group(nil, nil, nil)
    end
  end

  def find_resources_for_group(
        _group,
        _args,
        _resolution
      ) do
    {:ok, %Page{total: 0, elements: []}}
  end

  def find_resources_for_parent(
        %Resource{actor_id: group_id} = parent,
        _args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         %Page{} = page <- Resources.get_resources_for_folder(parent) do
      {:ok, page}
    end
  end

  def find_resources_for_parent(_parent, _args, _resolution),
    do: {:ok, %Page{total: 0, elements: []}}

  def get_resource(
        _parent,
        %{path: path, username: username},
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with {:current_actor, %Actor{id: actor_id}} <-
           {:current_actor, Users.get_actor_for_user(user)},
         {:group, %Actor{id: group_id}} <- {:group, Actors.get_actor_by_name(username, :Group)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:resource, %Resource{} = resource} <-
           {:resource, Resources.get_resource_by_group_and_path_with_preloads(group_id, path)} do
      {:ok, resource}
    else
      {:group, _} -> {:error, :group_not_found}
      {:member, false} -> {:error, dgettext("errors", "Profile is not member of group")}
      {:resource, _} -> {:error, :resource_not_found}
    end
  end

  def get_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to access resources")}
  end

  def create_resource(
        _parent,
        %{actor_id: group_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         parent <- get_eventual_parent(args),
         {:own_check, true} <- {:own_check, check_resource_owned_by_group(parent, group_id)},
         {:ok, _, %Resource{} = resource} <-
           ActivityPub.create(
             :resource,
             args
             |> Map.put(:actor_id, group_id)
             |> Map.put(:creator_id, actor_id),
             true,
             %{}
           ) do
      {:ok, resource}
    else
      {:error, _} ->
        {:error, dgettext("errors", "Error while creating resource")}

      {:own_check, _} ->
        {:error, dgettext("errors", "Parent resource doesn't belong to this group")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def create_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to create resources")}
  end

  def update_resource(
        _parent,
        %{id: resource_id} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id, url: actor_url} <- Users.get_actor_for_user(user),
         {:resource, %Resource{actor_id: group_id} = resource} <-
           {:resource, Resources.get_resource_with_preloads(resource_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Resource{} = resource} <-
           ActivityPub.update(resource, args, true, %{"actor" => actor_url}) do
      {:ok, resource}
    else
      {:resource, _} ->
        {:error, dgettext("errors", "Resource doesn't exist")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def update_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update resources")}
  end

  def delete_resource(
        _parent,
        %{id: resource_id},
        %{
          context: %{
            current_user: %User{} = user
          }
        } = _resolution
      ) do
    with %Actor{id: actor_id} = actor <- Users.get_actor_for_user(user),
         {:resource, %Resource{parent_id: _parent_id, actor_id: group_id} = resource} <-
           {:resource, Resources.get_resource_with_preloads(resource_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Resource{} = resource} <-
           ActivityPub.delete(resource, actor) do
      {:ok, resource}
    else
      {:resource, _} ->
        {:error, dgettext("errors", "Resource doesn't exist")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def delete_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to delete resources")}
  end

  def preview_resource_link(
        _parent,
        %{resource_url: resource_url},
        %{
          context: %{
            current_user: %User{} = _user
          }
        } = _resolution
      ) do
    case Parser.parse(resource_url) do
      {:ok, data} when is_map(data) ->
        {:ok, struct(Metadata, data)}

      {:error, :invalid_parsed_data} ->
        {:error, dgettext("errors", "Unable to fetch resource details from this URL.")}

      {:error, err} ->
        Logger.warn("Error while fetching preview from #{inspect(resource_url)}")
        Logger.debug(inspect(err))
        {:error, :unknown_resource}
    end
  end

  def preview_resource_link(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to view a resource preview")}
  end

  def proxyify_pictures(%Metadata{} = metadata, _args, %{
        definition: %{schema_node: %{name: name}}
      }) do
    case name do
      "image_remote_url" -> {:ok, proxify_picture(metadata.image_remote_url)}
      "favicon_url" -> {:ok, proxify_picture(metadata.favicon_url)}
      _ -> {:error, "Unknown field"}
    end
  end

  @spec get_eventual_parent(map()) :: Resource.t() | nil
  defp get_eventual_parent(args) do
    parent = args |> Map.get(:parent_id) |> get_parent_resource()

    case parent do
      %Resource{} -> parent
      _ -> nil
    end
  end

  @spec get_parent_resource(integer | nil) :: nil | Resource.t()
  defp get_parent_resource(nil), do: nil
  defp get_parent_resource(parent_id), do: Resources.get_resource(parent_id)

  @spec check_resource_owned_by_group(Resource.t() | nil, integer) :: boolean
  defp check_resource_owned_by_group(nil, _group_id), do: true

  defp check_resource_owned_by_group(%Resource{actor_id: actor_id}, group_id)
       when is_binary(group_id),
       do: actor_id == String.to_integer(group_id)

  defp check_resource_owned_by_group(%Resource{actor_id: actor_id}, group_id)
       when is_number(group_id),
       do: actor_id == group_id

  @spec proxify_picture(String.t() | nil) :: String.t() | nil
  defp proxify_picture(nil), do: nil

  defp proxify_picture(url) do
    MediaProxy.url(url)
  end
end
