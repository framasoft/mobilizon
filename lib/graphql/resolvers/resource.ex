defmodule Mobilizon.GraphQL.Resolvers.Resource do
  @moduledoc """
  Handles the resources-related GraphQL calls
  """

  alias Mobilizon.{Actors, Resources}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actions
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
  @spec find_resources_for_group(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Resource.t())}
  def find_resources_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        } = _resolution
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
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

  @spec find_resources_for_parent(Resource.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Resource.t())}
  def find_resources_for_parent(
        %Resource{actor_id: group_id} = parent,
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        } = _resolution
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         %Page{} = page <- Resources.get_resources_for_folder(parent, page, limit) do
      {:ok, page}
    end
  end

  def find_resources_for_parent(_parent, _args, _resolution),
    do: {:ok, %Page{total: 0, elements: []}}

  @spec get_resource(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Resource.t()} | {:error, :group_not_found | :resource_not_found | String.t()}
  def get_resource(
        _parent,
        %{path: path, username: username},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        } = _resolution
      ) do
    Logger.debug("Getting resource for group with username #{username}")

    with {:group, %Actor{id: group_id}} <- {:group, Actors.get_actor_by_name(username, :Group)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
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

  @spec create_resource(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Resource.t()} | {:error, String.t()}
  def create_resource(
        _parent,
        %{actor_id: group_id} = args,
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        } = _resolution
      ) do
    if Actors.member?(actor_id, group_id) do
      parent = get_eventual_parent(args)

      if check_resource_owned_by_group(parent, group_id) do
        case Actions.Create.create(
               :resource,
               args
               |> Map.put(:actor_id, group_id)
               |> Map.put(:creator_id, actor_id),
               true,
               %{}
             ) do
          {:ok, _, %Resource{} = resource} ->
            {:ok, resource}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, changeset}

          {:error, _err} ->
            {:error, dgettext("errors", "Error while creating resource")}
        end
      else
        {:error, dgettext("errors", "Parent resource doesn't belong to this group")}
      end
    else
      {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def create_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to create resources")}
  end

  @spec update_resource(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Resource.t()} | {:error, String.t()}
  def update_resource(
        _parent,
        %{id: resource_id} = args,
        %{
          context: %{
            current_actor: %Actor{id: actor_id, url: actor_url}
          }
        } = _resolution
      ) do
    case Resources.get_resource_with_preloads(resource_id) do
      %Resource{actor_id: group_id} = resource ->
        if Actors.member?(actor_id, group_id) do
          case Actions.Update.update(resource, args, true, %{"actor" => actor_url}) do
            {:ok, _, %Resource{} = resource} ->
              {:ok, resource}

            {:error, %Ecto.Changeset{} = err} ->
              {:error, err}

            {:error, err} when is_atom(err) ->
              {:error, dgettext("errors", "Unknown error while updating resource")}
          end
        else
          {:error, dgettext("errors", "Profile is not member of group")}
        end

      nil ->
        {:error, dgettext("errors", "Resource doesn't exist")}
    end
  end

  def update_resource(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update resources")}
  end

  @spec delete_resource(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Resource.t()} | {:error, String.t()}
  def delete_resource(
        _parent,
        %{id: resource_id},
        %{
          context: %{
            current_actor: %Actor{id: actor_id} = actor
          }
        } = _resolution
      ) do
    with {:resource, %Resource{parent_id: _parent_id, actor_id: group_id} = resource} <-
           {:resource, Resources.get_resource_with_preloads(resource_id)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         {:ok, _, %Resource{} = resource} <-
           Actions.Delete.delete(resource, actor) do
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

  @spec preview_resource_link(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Metadata.t()} | {:error, String.t() | :unknown_resource}
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

      {:error, _error_type, _} ->
        {:error, dgettext("errors", "Unable to fetch resource details from this URL.")}
    end
  end

  def preview_resource_link(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to view a resource preview")}
  end

  @spec proxyify_pictures(Metadata.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, String.t() | nil} | {:error, String.t()}
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
