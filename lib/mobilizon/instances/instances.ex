defmodule Mobilizon.Instances do
  @moduledoc """
  The instances context
  """
  alias Ecto.Adapters.SQL
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Instances.{Instance, InstanceActor}
  alias Mobilizon.Storage.{Page, Repo}
  import Ecto.Query

  @is_null_fragment "CASE WHEN ? IS NULL THEN FALSE ELSE TRUE END"

  @spec instances(Keyword.t()) :: Page.t(Instance.t())
  def instances(options) do
    page = Keyword.get(options, :page, 1)
    limit = Keyword.get(options, :limit, 10)
    order_by = Keyword.get(options, :order_by, :event_count)
    direction = Keyword.get(options, :direction, :desc)
    filter_domain = Keyword.get(options, :filter_domain)
    # suspend_status = Keyword.get(options, :filter_suspend_status, :all)
    follow_status = Keyword.get(options, :filter_follow_status, :all)

    order_by_options = Keyword.new([{direction, order_by}])

    %Actor{id: relay_id} = Relay.get_actor()

    query =
      Instance
      |> join(:left, [i], ia in InstanceActor, on: i.domain == ia.domain)
      |> join(:left, [_i, ia], a in Actor, on: ia.actor_id == a.id)
      # following
      |> join(:left, [_i, _ia, a], f1 in Follower, on: f1.target_actor_id == a.id)
      # followed
      |> join(:left, [_i, _ia, a], f2 in Follower, on: f2.actor_id == a.id)
      |> select([i, ia, a, f1, f2], %{
        instance: i,
        instance_actor: ia,
        actor: a,
        domain: a.domain,
        has_relay: fragment(@is_null_fragment, a.id),
        following: fragment(@is_null_fragment, f2.id),
        following_approved: f2.approved,
        follower: fragment(@is_null_fragment, f1.id),
        follower_approved: f1.approved
      })
      |> order_by(^order_by_options)

    query =
      if is_nil(filter_domain) or filter_domain == "" do
        query
      else
        where(
          query,
          [i, ia],
          like(i.domain, ^"%#{filter_domain}%") or like(ia.instance_name, ^"%#{filter_domain}%")
        )
      end

    query =
      case follow_status do
        :following ->
          where(query, [_i, _ia, _a, f1], f1.actor_id == ^relay_id and f1.approved == true)

        :followed ->
          where(
            query,
            [_i, _ia, _a, _f1, f2],
            f2.target_actor_id == ^relay_id and f2.approved == true
          )

        :all ->
          query
      end

    %Page{elements: elements} = paged_instances = Page.build_page(query, page, limit)

    %Page{
      paged_instances
      | elements: Enum.map(elements, &convert_instance_meta/1)
    }
  end

  @spec instance(String.t()) :: Instance.t() | nil
  def instance(domain) do
    Instance
    |> where(domain: ^domain)
    |> Repo.one()
  end

  @spec all_domains :: list(Instance.t())
  def all_domains do
    Instance
    |> distinct(true)
    |> select([:domain])
    |> Repo.all()
  end

  @spec refresh :: %{
          :rows => nil | [[term()] | binary()],
          :num_rows => non_neg_integer(),
          optional(atom()) => any()
        }
  def refresh do
    SQL.query!(Repo, "REFRESH MATERIALIZED VIEW instances")
  end

  defp convert_instance_meta(%{
         instance: instance,
         instance_actor: instance_meta,
         actor: instance_actor,
         domain: _domain,
         follower: follower,
         follower_approved: follower_approved,
         following: following,
         following_approved: following_approved,
         has_relay: has_relay
       }) do
    instance
    |> Map.put(:follower_status, follow_status(following, following_approved))
    |> Map.put(:followed_status, follow_status(follower, follower_approved))
    |> Map.put(:has_relay, has_relay)
    |> Map.put(
      :relay_address,
      if(is_nil(instance_actor),
        do: nil,
        else: Actor.preferred_username_and_domain(instance_actor)
      )
    )
    |> Map.put(:instance_actor, instance_actor)
    |> add_metadata_details(instance_meta)
  end

  @spec add_metadata_details(map(), InstanceActor.t() | nil) :: map()
  defp add_metadata_details(instance, nil), do: instance

  defp add_metadata_details(instance, instance_meta) do
    instance
    |> Map.put(:instance_name, instance_meta.instance_name)
    |> Map.put(:instance_description, instance_meta.instance_description)
    |> Map.put(:software, instance_meta.software)
    |> Map.put(:software_version, instance_meta.software_version)
  end

  defp follow_status(true, true), do: :approved
  defp follow_status(true, false), do: :pending
  defp follow_status(false, _), do: :none
  defp follow_status(nil, _), do: :none

  @spec get_instance_actor(String.t()) :: InstanceActor.t() | nil
  def get_instance_actor(domain) do
    InstanceActor
    |> Repo.get_by(domain: domain)
    |> Repo.preload(:actor)
  end

  @doc """
  Creates an instance actor.
  """
  @spec create_instance_actor(map) :: {:ok, InstanceActor.t()} | {:error, Ecto.Changeset.t()}
  def create_instance_actor(attrs \\ %{}) do
    with {:ok, %InstanceActor{} = instance_actor} <-
           %InstanceActor{}
           |> InstanceActor.changeset(attrs)
           |> Repo.insert(on_conflict: :replace_all, conflict_target: :domain) do
      {:ok, Repo.preload(instance_actor, :actor)}
    end
  end

  @doc """
  Updates an instance actor.
  """
  @spec update_instance_actor(InstanceActor.t(), map) ::
          {:ok, InstanceActor.t()} | {:error, Ecto.Changeset.t()}
  def update_instance_actor(%InstanceActor{} = instance_actor, attrs) do
    with {:ok, %InstanceActor{} = instance_actor} <-
           instance_actor
           |> Repo.preload(:actor)
           |> InstanceActor.changeset(attrs)
           |> Repo.update() do
      {:ok, Repo.preload(instance_actor, :actor)}
    end
  end

  @doc """
  Deletes a post
  """
  @spec delete_instance_actor(InstanceActor.t()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def delete_instance_actor(%InstanceActor{} = instance_actor) do
    Repo.delete(instance_actor)
  end
end
