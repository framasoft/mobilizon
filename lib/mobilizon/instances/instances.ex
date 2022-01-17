defmodule Mobilizon.Instances do
  @moduledoc """
  The instances context
  """
  alias Ecto.Adapters.SQL
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Instances.Instance
  alias Mobilizon.Storage.{Page, Repo}
  import Ecto.Query

  @is_null_fragment "CASE WHEN ? IS NULL THEN FALSE ELSE TRUE END"

  @spec instances(Keyword.t()) :: Page.t(Instance.t())
  def instances(options) do
    page = Keyword.get(options, :page)
    limit = Keyword.get(options, :limit)
    order_by = Keyword.get(options, :order_by)
    direction = Keyword.get(options, :direction)
    filter_domain = Keyword.get(options, :filter_domain)
    # suspend_status = Keyword.get(options, :filter_suspend_status)
    follow_status = Keyword.get(options, :filter_follow_status)

    order_by_options = Keyword.new([{direction, order_by}])

    subquery =
      Actor
      |> where(
        [a],
        a.preferred_username == "relay" and a.type == :Application and not is_nil(a.domain)
      )
      |> join(:left, [a], f1 in Follower, on: f1.target_actor_id == a.id)
      |> join(:left, [a], f2 in Follower, on: f2.actor_id == a.id)
      |> select([a, f1, f2], %{
        domain: a.domain,
        has_relay: fragment(@is_null_fragment, a.id),
        following: fragment(@is_null_fragment, f2.id),
        following_approved: f2.approved,
        follower: fragment(@is_null_fragment, f1.id),
        follower_approved: f1.approved
      })

    query =
      Instance
      |> join(:left, [i], s in subquery(subquery), on: i.domain == s.domain)
      |> select([i, s], {i, s})
      |> order_by(^order_by_options)

    query =
      if is_nil(filter_domain) or filter_domain == "" do
        query
      else
        where(query, [i], like(i.domain, ^"%#{filter_domain}%"))
      end

    query =
      case follow_status do
        :following -> where(query, [i, s], s.following == true)
        :followed -> where(query, [i, s], s.follower == true)
        :all -> query
      end

    %Page{elements: elements} = paged_instances = Page.build_page(query, page, limit, :domain)

    %Page{
      paged_instances
      | elements: Enum.map(elements, &convert_instance_meta/1)
    }
  end

  @spec instance(String.t()) :: Instance.t()
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

  defp convert_instance_meta(
         {instance,
          %{
            domain: _domain,
            follower: follower,
            follower_approved: follower_approved,
            following: following,
            following_approved: following_approved,
            has_relay: has_relay
          }}
       ) do
    instance
    |> Map.put(:follower_status, follow_status(following, following_approved))
    |> Map.put(:followed_status, follow_status(follower, follower_approved))
    |> Map.put(:has_relay, has_relay)
  end

  defp follow_status(true, true), do: :approved
  defp follow_status(true, false), do: :pending
  defp follow_status(false, _), do: :none
  defp follow_status(nil, _), do: :none
end
