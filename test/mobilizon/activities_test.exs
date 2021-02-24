defmodule Mobilizon.ActivitiesTest do
  use Mobilizon.DataCase

  alias Mobilizon.Activities
  import Mobilizon.Factory

  describe "activities" do
    alias Mobilizon.Activities.Activity

    @valid_attrs %{
      message: "some message",
      message_params: %{},
      type: "event",
      object_id: "some object_id",
      subject: "event_created",
      subject_params: %{}
    }

    @invalid_attrs %{
      message: nil,
      object_id: nil,
      subject: nil
    }

    setup do
      actor = insert(:actor)
      group = insert(:group)
      {:ok, actor: actor, group: group}
    end

    def activity_fixture(attrs \\ %{}) do
      {:ok, activity} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Activities.create_activity()

      activity
    end

    test "list_activities/0 returns all activities", %{actor: actor, group: group} do
      activity =
        activity_fixture(%{
          group_id: group.id,
          author_id: actor.id,
          inserted_at: DateTime.utc_now()
        })

      assert Activities.list_activities() == [activity]
    end

    test "get_activity!/1 returns the activity with given id", %{actor: actor, group: group} do
      activity =
        activity_fixture(%{
          author_id: actor.id,
          group_id: group.id,
          inserted_at: DateTime.utc_now()
        })

      assert Activities.get_activity!(activity.id) == activity
    end

    test "create_activity/1 with valid data creates a activity", %{actor: actor, group: group} do
      assert {:ok, %Activity{} = activity} =
               Activities.create_activity(
                 @valid_attrs
                 |> Map.put(:group_id, group.id)
                 |> Map.put(:author_id, actor.id)
                 |> Map.put(:inserted_at, DateTime.utc_now())
               )

      assert activity.message == "some message"
      assert activity.message_params == %{}
      assert activity.object_id == "some object_id"
      assert activity.subject == :event_created
      assert activity.subject_params == %{}
    end

    test "create_activity/1 with invalid data returns error changeset", %{
      actor: actor,
      group: group
    } do
      assert {:error, %Ecto.Changeset{}} =
               Activities.create_activity(
                 @invalid_attrs
                 |> Map.put(:author_id, actor.id)
                 |> Map.put(:group_id, group.id)
                 |> Map.put(:inserted_at, DateTime.utc_now())
               )
    end
  end
end
