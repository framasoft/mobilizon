defmodule Mobilizon.Service.Workers.SendActivityRecapWorkerTest do
  @moduledoc """
  Test the SendActivityRecapWorker module
  """

  alias Mobilizon.{Activities, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Workers.SendActivityRecapWorker
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.{ActivitySetting, Setting, User}

  use Mobilizon.DataCase
  import Swoosh.TestAssertions
  import Mobilizon.Factory

  describe "Send activity recap" do
    # Skipped because this depends on the test being run between @start_time and @end_time
    @tag :skip
    test "not if we already have sent notifications" do
      %User{} = user = insert(:user)
      %Actor{} = actor = insert(:actor, user: user)
      %Actor{} = group = insert(:group)

      insert(:member,
        parent: group,
        actor: actor,
        role: :administrator,
        member_since: DateTime.add(DateTime.utc_now(), -3600)
      )

      %Activity{id: activity_id} =
        insert(:mobilizon_activity, inserted_at: DateTime.utc_now(), group: group)

      assert %Page{elements: [%Activity{id: ^activity_id}], total: 1} =
               Activities.list_group_activities(group.id)

      assert [%Activity{id: ^activity_id}] =
               Activities.list_group_activities_for_recap(group.id, actor.id)

      old = DateTime.utc_now() |> DateTime.add(-3600 * 24 * 3) |> DateTime.truncate(:second)

      %Setting{} =
        user_settings =
        insert(:settings,
          user: user,
          user_id: user.id,
          group_notifications: :one_day,
          last_notification_sent: old
        )

      %ActivitySetting{} =
        activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

      Users.update_user(user, %{settings: user_settings, activity_settings: [activity_setting]})
      assert old == Users.get_user_with_settings!(user.id).settings.last_notification_sent

      assert :ok == SendActivityRecapWorker.perform(%Oban.Job{})

      assert_email_sent(to: user.email)

      assert %{last_notification_sent: updated_last_notification_sent} =
               Users.get_setting(user.id)

      assert old != updated_last_notification_sent
      assert DateTime.diff(DateTime.utc_now(), updated_last_notification_sent) < 5

      assert :ok == SendActivityRecapWorker.perform(%Oban.Job{})

      refute_email_sent()
    end
  end
end
