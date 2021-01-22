defmodule Mobilizon.Resources do
  @moduledoc """
  The Resources context.
  """
  alias Ecto.Adapters.SQL
  alias Ecto.Multi
  alias Ecto.UUID
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Storage.{Page, Repo}

  import Ecto.Query
  require Logger

  @resource_preloads [:actor, :creator, :children, :parent]

  @doc """
  Returns the list of recent resources for a group
  """
  @spec get_resources_for_group(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def get_resources_for_group(%Actor{id: group_id}, page \\ nil, limit \\ nil) do
    Resource
    |> where(actor_id: ^group_id)
    |> order_by(desc: :published_at)
    |> preload([r], [:actor, :creator])
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of top-level resources for a group
  """
  def get_top_level_resources_for_group(%Actor{id: group_id}, page \\ nil, limit \\ nil) do
    get_resources_for_folder(%Resource{id: "root_something", actor_id: group_id}, page, limit)
  end

  @doc """
  Returns the list of resources for a resource folder.
  """
  @spec get_resources_for_folder(Resource.t(), integer | nil, integer | nil) :: Page.t()
  def get_resources_for_folder(resource, page \\ nil, limit \\ nil)

  def get_resources_for_folder(
        %Resource{id: "root_" <> _group_id, actor_id: group_id},
        page,
        limit
      ) do
    Resource
    |> where([r], r.actor_id == ^group_id and is_nil(r.parent_id))
    |> order_by(asc: :type)
    |> preload([r], [:actor, :creator])
    |> Page.build_page(page, limit)
  end

  def get_resources_for_folder(%Resource{id: resource_id}, page, limit) do
    Resource
    |> where([r], r.parent_id == ^resource_id)
    |> order_by(asc: :type)
    |> preload([r], [:actor, :creator])
    |> Page.build_page(page, limit)
  end

  @doc """
  Get a resource by it's ID
  """
  @spec get_resource(integer | String.t()) :: Resource.t() | nil
  def get_resource(nil), do: nil
  def get_resource(id), do: Repo.get(Resource, id)

  @spec get_resource_with_preloads(integer | String.t()) :: Resource.t() | nil
  def get_resource_with_preloads(id) do
    Resource
    |> Repo.get(id)
    |> Repo.preload(@resource_preloads)
  end

  @spec get_resource_by_group_and_path_with_preloads(String.t() | integer, String.t()) ::
          Resource.t() | nil
  def get_resource_by_group_and_path_with_preloads(group_id, "/") do
    with {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id) do
      %Resource{
        actor_id: group_id,
        id: "root_#{group_id}",
        actor: group,
        path: "/",
        title: "Root"
      }
    end
  end

  def get_resource_by_group_and_path_with_preloads(group_id, path) do
    Resource
    |> Repo.get_by(actor_id: group_id, path: path)
    |> Repo.preload(@resource_preloads)
  end

  @doc """
  Get a resource by it's URL
  """
  @spec get_resource_by_url(String.t()) :: Resource.t() | nil
  def get_resource_by_url(url), do: Repo.get_by(Resource, url: url)

  @spec get_resource_by_url_with_preloads(String.t()) :: Resource.t() | nil
  def get_resource_by_url_with_preloads(url) do
    Resource
    |> Repo.get_by(url: url)
    |> Repo.preload(@resource_preloads)
  end

  @doc """
  Creates a resource.
  """
  @spec create_resource(map) :: {:ok, Resource.t()} | {:error, Ecto.Changeset.t()}
  def create_resource(attrs \\ %{}) do
    Multi.new()
    |> do_find_parent_path(Map.get(attrs, :parent_id))
    |> Multi.insert(:insert, fn %{find_parent_path: path} ->
      Resource.changeset(%Resource{}, Map.put(attrs, :path, "#{path}/#{attrs.title}"))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{insert: %Resource{} = resource}} ->
        {:ok, resource}

      {:error, operation, reason, _changes} ->
        {:error, "Error while inserting resource when #{operation} because of #{inspect(reason)}"}
    end
  end

  @doc """
  Updates a resource.

  Since a resource can be a folder and hold children, we do the following in a transaction:
    * Get the parent path so that we can reconstruct the path for current resource (if moved or simply renamed)
    * Update all children with the new parent path
    * Update the resource path itself
  """
  @spec update_resource(Resource.t(), map) :: {:ok, Resource.t()} | {:error, Ecto.Changeset.t()}
  def update_resource(%Resource{title: old_title} = resource, attrs) do
    Multi.new()
    |> find_parent_path(resource, attrs)
    |> update_children(resource, attrs)
    |> Multi.update(:update, fn %{find_parent_path: path} ->
      title = Map.get(attrs, :title, old_title)
      Resource.changeset(resource, Map.put(attrs, :path, "#{path}/#{title}"))
    end)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         find_parent_path: _parent_path,
         update: %Resource{} = resource,
         update_children: children
       }} ->
        resource = Map.put(resource, :children, children)
        {:ok, resource}

      # collect errors into record changesets
      {:error, operation, reason, _changes} ->
        {:error, "Error while updating resource when #{operation} because of #{inspect(reason)}"}
    end
  end

  @spec find_parent_path(Multi.t(), Resource.t(), map()) :: Multi.t()
  defp find_parent_path(
         %Multi{} = multi,
         %Resource{parent_id: old_parent_id} = _resource,
         attrs
       ) do
    updated_parent_id = Map.get(attrs, :parent_id, old_parent_id)
    Logger.debug("Finding parent path for updated_parent_id #{inspect(updated_parent_id)}")
    do_find_parent_path(multi, updated_parent_id)
  end

  @spec do_find_parent_path(Multi.t(), String.t() | nil) :: Multi.t()
  defp do_find_parent_path(%Multi{} = multi, nil),
    do: Multi.run(multi, :find_parent_path, fn _, _ -> {:ok, ""} end)

  defp do_find_parent_path(%Multi{} = multi, parent_id) do
    Multi.run(multi, :find_parent_path, fn _repo, _changes ->
      case get_resource(parent_id) do
        %Resource{path: path} = _resource -> {:ok, path}
        _ -> {:error, :not_found}
      end
    end)
  end

  # sobelow_skip ["SQL.Query"]
  @spec update_children(Multi.t(), Resource.t(), map()) :: Multi.t()
  defp update_children(
         %Multi{} = multi,
         %Resource{
           id: id,
           type: :folder,
           title: old_title,
           actor_id: actor_id
         },
         attrs
       ) do
    title = Map.get(attrs, :title, old_title)

    Multi.run(multi, :update_children, fn repo, %{find_parent_path: path} ->
      {:ok, uuid} = UUID.dump(id)

      {query, params} =
        {"UPDATE resource SET path = CONCAT($1::text, title) WHERE actor_id = $2 AND parent_id = $3::uuid",
         ["#{path}/#{title}/", actor_id, uuid]}

      {:ok, _} =
        SQL.query(
          repo,
          query,
          params
        )

      children = repo.all(from(r in Resource, where: r.parent_id == ^id))

      {:ok, children}
    end)
  end

  defp update_children(multi, _, _),
    do: Multi.run(multi, :update_children, fn _, _ -> {:ok, ""} end)

  @doc """
  Deletes a resource
  """
  @spec delete_resource(Resource.t()) :: {:ok, Resource.t()} | {:error, Ecto.Changeset.t()}
  def delete_resource(%Resource{} = resource), do: Repo.delete(resource)
end
