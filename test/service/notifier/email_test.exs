defmodule Mobilizon.Service.Notifier.EmailTest do
  @moduledoc """
  Test the Email notifier module
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Notifier.Email
  alias Mobilizon.Users.{ActivitySetting, Setting, User}

  use Mobilizon.DataCase
  import Swoosh.TestAssertions
  import Mobilizon.Factory

  describe "Returns if the module is loaded" do
    test "Loaded by default" do
      assert Email.ready?() == true
    end

    test "If disabled" do
      Config.put([Email, :enabled], false)
      assert Email.ready?() == false
      Config.put([Email, :enabled], true)
    end
  end

  describe "sending email for activities" do
    test "when the user doesn't allow it" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user, activity_settings: [])
      %Setting{} = user_settings = insert(:settings, user_id: user.id, group_notifications: :none)
      user = %User{user | settings: user_settings}

      assert {:ok, :skipped} == Email.send(user, activity)

      refute_email_sent()
    end

    test "when the user allows it" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user)

      %Setting{} =
        user_settings = insert(:settings, user_id: user.id, group_notifications: :direct)

      %ActivitySetting{} =
        activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}

      assert {:ok, :sent} == Email.send(user, activity)

      assert_email_sent(to: user.email)
    end

    test "if it's been an hour since the last notification" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user)

      %Setting{} =
        user_settings =
        insert(:settings,
          user_id: user.id,
          group_notifications: :one_hour,
          last_notification_sent: DateTime.add(DateTime.utc_now(), -3_659)
        )

      %ActivitySetting{} =
        activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}

      assert {:ok, :sent} == Email.send(user, activity)

      assert_email_sent(to: user.email)
    end

    test "if there's no delay since the last notification" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user)

      %Setting{} =
        user_settings =
        insert(:settings,
          user_id: user.id,
          group_notifications: :one_hour,
          last_notification_sent: nil
        )

      %ActivitySetting{} =
        activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}

      assert {:ok, :sent} == Email.send(user, activity)

      assert_email_sent(to: user.email)
    end

    test "not if we already have sent notifications" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user)

      old = DateTime.add(DateTime.utc_now(), -3600 * 24 * 3)

      %Setting{} =
        user_settings =
        insert(:settings,
          user_id: user.id,
          group_notifications: :one_day,
          last_notification_sent: old
        )

      %ActivitySetting{} =
        activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}

      assert {:ok, :sent} == Email.send(user, activity, recap: :one_day)

      assert_email_sent(to: user.email)

      assert %{last_notification_sent: updated_last_notification_sent} =
               user_settings = Users.get_setting(user.id)

      assert old != updated_last_notification_sent
      assert DateTime.diff(DateTime.utc_now(), updated_last_notification_sent) < 5

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}

      assert {:ok, :skipped} == Email.send(user, activity, recap: :one_day)

      refute_email_sent()
    end
  end

  describe "send_anonymous_activity" do
    @email "someone@somewhere.tld"

    test "send activity notification to anonymous user" do
      %Activity{} =
        activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now(), type: :comment)

      Email.send_anonymous_activity(@email, activity, locale: "en")

      assert_email_sent(to: @email)
    end
  end
end
