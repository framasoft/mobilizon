defmodule Mobilizon.Service.Workers.ActivityBuilderTest do
  @moduledoc """
  Test the ActivityBuilder module
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Notifier.Mock2, as: NotifierMock
  alias Mobilizon.Service.Workers.ActivityBuilder
  alias Mobilizon.Users.User

  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox

  setup_all do
    Mox.defmock(NotifierMock, for: Mobilizon.Service.Notifier)

    Mobilizon.Config.put([Mobilizon.Service.Notifier, :notifiers], [
      NotifierMock
    ])

    :ok
  end

  setup :verify_on_exit!

  describe "Sends direct email notification to users" do
    test "if the user has a profile member of a group" do
      %User{} = user = insert(:user)

      %Actor{} = actor = insert(:actor, user: user)

      %Actor{type: :Group} = group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      %Activity{} =
        activity = insert(:mobilizon_activity, group: group, inserted_at: DateTime.utc_now())

      NotifierMock
      |> expect(:ready?, 1, fn -> true end)
      |> expect(:send, 1, fn %User{},
                             %Activity{
                               type: :event,
                               subject: :event_created,
                               object_type: :event
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == ActivityBuilder.notify_activity(activity)
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

      NotifierMock
      |> expect(:ready?, 0, fn -> true end)
      |> expect(:send, 0, fn %User{},
                             %Activity{
                               type: :event,
                               subject: :event_created,
                               object_type: :event
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)
    end
  end
end
