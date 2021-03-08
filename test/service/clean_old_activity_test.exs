defmodule Mobilizon.Service.CleanOldActivityTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Activities, Config}
  alias Mobilizon.Service.CleanOldActivity

  @activity_inserted_at_1 DateTime.from_iso8601("2019-01-02T10:33:39.207493Z") |> elem(1)
  @activity_inserted_at_2 DateTime.utc_now()

  setup do
    group1 = insert(:group)
    group2 = insert(:group)
    Config.clear_config_cache()

    {:ok, group1: group1, group2: group2}
  end

  describe "clean old activities" do
    test "with default settings", %{group1: group1, group2: group2} do
      create_activities(group1, group2)
      Config.put([:instance, :activity_expire_days], 100)
      Config.put([:instance, :activity_keep_number], 5)
      assert Activities.list_group_activities(group1.id).total == 10
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 1, activities: 5} == CleanOldActivity.clean(dry_run: true)

      assert Activities.list_group_activities(group1.id).total == 10
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 1, activities: 5} == CleanOldActivity.clean()

      assert Activities.list_group_activities(group1.id).total == 5
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 0, activities: 0} == CleanOldActivity.clean()

      assert Activities.list_group_activities(group1.id).total == 5
      assert Activities.list_group_activities(group2.id).total == 5
      Config.put([:instance, :activity_expire_days], 365)
      Config.put([:instance, :activity_keep_number], 100)
    end

    test "with custom settings", %{group1: group1, group2: group2} do
      create_activities(group1, group2)
      assert Activities.list_group_activities(group1.id).total == 10
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 1, activities: 5} ==
               CleanOldActivity.clean(grace_period: 100, activity_keep_number: 5, dry_run: true)

      assert Activities.list_group_activities(group1.id).total == 10
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 1, activities: 5} ==
               CleanOldActivity.clean(grace_period: 100, activity_keep_number: 5)

      assert Activities.list_group_activities(group1.id).total == 5
      assert Activities.list_group_activities(group2.id).total == 5

      assert {:ok, actors: 0, activities: 0} ==
               CleanOldActivity.clean(grace_period: 100, activity_keep_number: 5)

      assert Activities.list_group_activities(group1.id).total == 5
      assert Activities.list_group_activities(group2.id).total == 5
    end
  end

  defp create_activities(group1, group2) do
    Enum.each(1..5, fn _ ->
      insert(:mobilizon_activity, group: group1, inserted_at: @activity_inserted_at_1)
    end)

    Enum.each(1..5, fn _ ->
      insert(:mobilizon_activity, group: group1, inserted_at: @activity_inserted_at_2)
    end)

    Enum.each(1..5, fn _ ->
      insert(:mobilizon_activity, group: group2, inserted_at: @activity_inserted_at_2)
    end)
  end
end
