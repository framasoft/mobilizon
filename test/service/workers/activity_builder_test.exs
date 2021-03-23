defmodule Mobilizon.Service.Workers.ActivityBuilderTest do
  @moduledoc """
  Test the ActivityBuilder module
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Workers.ActivityBuilder
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email.Activity, as: EmailActivity

  use Mobilizon.DataCase
  use Bamboo.Test

  import Mobilizon.Factory

  describe "Sends direct email notification to users" do
    test "if the user has a profile member of a group" do
      %User{} = user = insert(:user)

      %Actor{} = actor = insert(:actor, user: user)

      %Actor{type: :Group} = group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      %Activity{} =
        activity = insert(:mobilizon_activity, group: group, inserted_at: DateTime.utc_now())

      assert :ok == ActivityBuilder.notify_activity(activity)

      assert_delivered_email(
        EmailActivity.direct_activity(
          user.email,
          [activity]
        )
      )
    end

    test "unless if the user has a profile member of a group" do
      %User{} = user = insert(:user)

      %Actor{} = actor = insert(:actor, user: user)

      %Actor{type: :Group} = group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      %Activity{} =
        activity =
        insert(:mobilizon_activity, group: group, inserted_at: DateTime.utc_now(), author: actor)

      assert :ok == ActivityBuilder.notify_activity(activity)

      refute_delivered_email(
        EmailActivity.direct_activity(
          user.email,
          [activity]
        )
      )
    end
  end
end
