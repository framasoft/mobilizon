defmodule Mobilizon.FollowedGroupActivity do
  @moduledoc """
  Provide recent elements from groups that profiles follow
  """

  import Ecto.Query
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Storage.Page

  @spec user_followed_group_events(
          integer() | String.t(),
          DateTime.t() | nil,
          integer() | nil,
          integer() | nil
        ) :: Page.t(Event.t())
  def user_followed_group_events(user_id, after_datetime, page \\ nil, limit \\ nil) do
    Event
    |> distinct([e], e.id)
    |> join(:left, [e], p in Participant, on: e.id == p.event_id)
    |> join(:inner, [_e, p], pa in Actor, on: p.actor_id == pa.id)
    |> join(:inner, [e], g in Actor, on: e.attributed_to_id == g.id)
    |> join(:left, [_e, _p, _pa, g], f in Follower, on: g.id == f.target_actor_id)
    |> join(:left, [_e, _p, _pa, g], m in Member, on: g.id == m.parent_id)
    |> join(:inner, [_e, _p, pa, _g, f, m], a in Actor,
      on: a.id == f.actor_id or a.id == m.actor_id
    )
    |> add_after_datetime_filter(after_datetime)
    |> where(
      [_e, p, pa, _g, f, m, a],
      (f.approved or m.role in ^[:member, :moderator, :administrator, :creator]) and
        a.user_id == ^user_id and
        pa.user_id != ^user_id
    )
    |> preload([
      :organizer_actor,
      :attributed_to,
      :tags,
      :physical_address,
      :picture
    ])
    |> select([e, g, _f, _m, a], [
      e,
      g,
      a
    ])
    |> Page.build_page(page, limit)
  end

  @spec add_after_datetime_filter(Ecto.Query.t(), DateTime.t() | nil) :: Ecto.Query.t()
  defp add_after_datetime_filter(query, nil),
    do: where(query, [e], e.begins_on > ^DateTime.utc_now())

  defp add_after_datetime_filter(query, %DateTime{} = datetime),
    do: where(query, [e], e.begins_on > ^datetime)
end
