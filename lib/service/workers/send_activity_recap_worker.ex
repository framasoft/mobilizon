defmodule Mobilizon.Service.Workers.SendActivityRecapWorker do
  @moduledoc """
  Worker to send activity recaps
  """

  use Oban.Worker, queue: "notifications"
  alias Mobilizon.{Activities, Actors, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Notifier.Email
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.{Setting, User}

  import Mobilizon.Service.DateTime,
    only: [
      is_between_hours: 1,
      is_between_hours_on_first_day: 1,
      is_delay_ok_since_last_notification_sent: 1
    ]

  @impl Oban.Worker
  def perform(%Job{}) do
    Repo.transaction(fn ->
      Users.stream_users_for_recap()
      |> Enum.to_list()
      |> Repo.preload([:settings])
      |> Enum.filter(&filter_elegible_users/1)
      |> Enum.map(fn %User{} = user ->
        %{
          activities: activities_for_user(user),
          user: user
        }
      end)
      |> Enum.filter(fn %{activities: activities, user: _user} -> length(activities) > 0 end)
      |> Enum.map(fn %{
                       activities: activities,
                       user:
                         %User{settings: %Setting{group_notifications: group_notifications}} =
                           user
                     } ->
        Email.send(user, activities, recap: group_notifications)
      end)
    end)
  end

  defp activities_for_user(
         %User{settings: %Setting{last_notification_sent: last_notification_sent}} = user
       ) do
    user
    |> Users.get_actors_for_user()
    |> Enum.flat_map(&group_memberships(&1, last_notification_sent))
    |> Enum.uniq()
  end

  defp group_memberships(%Actor{id: actor_id} = actor, last_notification_sent) do
    actor
    |> group_memberships_for_actor()
    |> Enum.uniq()
    |> Enum.flat_map(&activities_for_group(&1, actor_id, last_notification_sent))
  end

  defp group_memberships_for_actor(%Actor{} = actor) do
    Actors.list_groups_member_of(actor)
  end

  defp activities_for_group(
         %Actor{id: group_id, type: :Group},
         actor_asking_id,
         last_notification_sent
       ) do
    group_id
    |> Activities.list_group_activities_for_recap(actor_asking_id, last_notification_sent)
    # Don't send my own activities
    |> Enum.filter(fn %Activity{author: %Actor{id: author_id}} -> author_id != actor_asking_id end)
  end

  defp filter_elegible_users(%User{
         settings: %Setting{last_notification_sent: nil, group_notifications: :one_hour}
       }) do
    true
  end

  defp filter_elegible_users(%User{
         settings: %Setting{
           last_notification_sent: %DateTime{} = last_notification_sent,
           group_notifications: :one_hour
         }
       }) do
    is_delay_ok_since_last_notification_sent(last_notification_sent)
  end

  # If we're between notification hours
  defp filter_elegible_users(%User{
         settings: %Setting{
           group_notifications: :one_day,
           timezone: timezone
         }
       }) do
    is_between_hours(timezone: timezone)
  end

  # If we're on the first day of the week between notification hours
  defp filter_elegible_users(%User{
         locale: locale,
         settings: %Setting{
           group_notifications: :one_week,
           timezone: timezone
         }
       }) do
    is_between_hours_on_first_day(timezone: timezone, locale: locale)
  end
end
