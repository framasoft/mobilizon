defmodule Mobilizon.Users.GuardsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  setup do
    user = insert(:user)
    moderator = insert(:user, role: :moderator)
    administrator = insert(:user, role: :administrator)
    {:ok, user: user, moderator: moderator, administrator: administrator}
  end

  describe "test guards" do
    import Mobilizon.Users.Guards

    test "is_moderator/1 guard", %{user: user, moderator: moderator, administrator: administrator} do
      refute is_moderator(user.role)
      assert is_moderator(moderator.role)
      assert is_moderator(administrator.role)
    end

    test "is_admin/1 guard", %{user: user, moderator: moderator, administrator: administrator} do
      refute is_admin(user.role)
      refute is_admin(moderator.role)
      assert is_admin(administrator.role)
    end
  end
end
