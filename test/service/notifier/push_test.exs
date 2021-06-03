defmodule Mobilizon.Service.Notifier.PushTest do
  @moduledoc """
  Test the Push notifier module
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Config
  alias Mobilizon.Service.Notifier.Push
  alias Mobilizon.Users.{ActivitySetting, Setting, User}

  use Mobilizon.DataCase
  use Bamboo.Test

  import Mobilizon.Factory

  describe "Returns if the module is loaded" do
    test "Loaded by default" do
      assert Push.ready?() == true
    end

    test "If disabled" do
      Config.put([Push, :enabled], false)
      assert Push.ready?() == false
      Config.put([Push, :enabled], true)
    end
  end

  describe "sending push notification for activities" do
    test "when the user doesn't allow it" do
      %Activity{} = activity = insert(:mobilizon_activity, inserted_at: DateTime.utc_now())
      %User{} = user = insert(:user)
      %Setting{} = user_settings = insert(:settings, user_id: user.id)
      user = %User{user | settings: user_settings}

      assert {:ok, :skipped} == Push.send(user, activity)
    end

    test "when the user allows it" do
      event = insert(:event)

      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          inserted_at: DateTime.utc_now(),
          object_id: to_string(event.id),
          subject_params: %{
            "event_title" => event.title,
            "event_uuid" => event.uuid,
            "event_id" => event.id
          }
        )

      %User{} = user = insert(:user)
      %Setting{} = user_settings = insert(:settings, user_id: user.id)

      %ActivitySetting{} =
        activity_setting =
        insert(:mobilizon_activity_setting, user_id: user.id, user: user, method: "push")

      user = %User{user | settings: user_settings, activity_settings: [activity_setting]}
      assert {:ok, :sent} == Push.send(user, activity)
    end
  end
end
