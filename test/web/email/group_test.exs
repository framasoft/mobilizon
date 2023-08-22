defmodule Mobilizon.Web.Email.GroupTest do
  @moduledoc """
  Test the Mobilizon.Web.Email.Group module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Users
  alias Mobilizon.Users.{ActivitySetting, Setting, User}
  alias Mobilizon.Web.Email.Group

  use Mobilizon.DataCase
  import Swoosh.TestAssertions
  import Mobilizon.Factory

  describe "Notify of new event" do
    @tag :skip
    test "members, followers, execept the ones that disabled it" do
      {_user_creator, actor} = insert_user_with_settings("user@creator.com")
      %Actor{} = group = insert(:group)
      %Event{} = event = insert(:event, attributed_to: group, organizer_actor: actor)

      insert(:member,
        parent: group,
        actor: actor,
        role: :administrator,
        member_since: DateTime.add(DateTime.utc_now(), -3600)
      )

      {_user_member, actor_member} = insert_user_with_settings("user@member.com")

      insert(:member,
        parent: group,
        actor: actor_member,
        role: :member,
        member_since: DateTime.add(DateTime.utc_now(), -3600)
      )

      {_user_pending_member, actor_pending_member} =
        insert_user_with_settings("user@pending.member.com")

      insert(:member,
        parent: group,
        actor: actor_pending_member,
        role: :not_approved
      )

      {_user_invited_member, actor_invited_member} =
        insert_user_with_settings("user@invited.member.com")

      insert(:member,
        parent: group,
        actor: actor_invited_member,
        role: :invited,
        member_since: DateTime.add(DateTime.utc_now(), -3600)
      )

      {_user_rejected_member, actor_rejected_member} =
        insert_user_with_settings("user@rejected.member.com")

      insert(:member,
        parent: group,
        actor: actor_rejected_member,
        role: :rejected,
        member_since: DateTime.add(DateTime.utc_now(), -3600)
      )

      {_user_approved_follower, actor_follower} =
        insert_user_with_settings("user@approved.follower.com")

      insert(:follower, actor: actor_follower, target_actor: group, approved: true)

      {_user_no_notify_follower, actor_follower_no_notify} =
        insert_user_with_settings("user@no-notify.follower.com")

      insert(:follower,
        actor: actor_follower_no_notify,
        target_actor: group,
        approved: true,
        notify: false
      )

      {_user_unapproved_follower, actor_unapproved_follower} =
        insert_user_with_settings("user@unapproved.follower.com")

      insert(:follower, actor: actor_unapproved_follower, target_actor: group, approved: false)

      # One profile has no notify, the other one has it
      {user_still_notify_follower, actor_follower_still_notify} =
        insert_user_with_settings("user@still-notify.follower.com")

      insert(:follower,
        actor: actor_follower_still_notify,
        target_actor: group,
        approved: true,
        notify: false
      )

      %Actor{} = actor_follower_with_notify = insert(:actor, user: user_still_notify_follower)

      insert(:follower,
        actor: actor_follower_with_notify,
        target_actor: group,
        approved: true,
        notify: true
      )

      %Actor{} = actor_remote_follower = insert(:actor, user: nil, domain: "some.remote.tld")

      insert(:follower,
        actor: actor_remote_follower,
        target_actor: group,
        approved: true,
        notify: true
      )

      assert :ok == Group.notify_of_new_event(event)

      refute_email_sent(to: "user@creator.com")
      refute_email_sent(to: "user@pending.member.com")
      refute_email_sent(to: "user@invited.member.com")
      refute_email_sent(to: "user@rejected.member.com")
      refute_email_sent(to: "user@unapproved.follower.com")
      refute_email_sent(to: "user@no-notify.follower.com")

      assert_email_sent(to: "user@member.com")
      assert_email_sent(to: "user@approved.follower.com")
      assert_email_sent(to: "user@still-notify.follower.com")
    end
  end

  defp insert_user_with_settings(email) do
    %User{} = user = insert(:user, email: email)

    %Actor{} = actor = insert(:actor, user: user)

    %Setting{} =
      user_settings =
      insert(:settings,
        user: user,
        user_id: user.id,
        group_notifications: :one_day
      )

    %ActivitySetting{} =
      activity_setting = insert(:mobilizon_activity_setting, user_id: user.id, user: user)

    {:ok, user} =
      Users.update_user(user, %{
        settings: user_settings,
        activity_settings: [activity_setting],
        default_actor_id: actor.id
      })

    {user, actor}
  end
end
