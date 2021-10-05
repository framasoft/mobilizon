defmodule Mobilizon.UsersTest do
  use Mobilizon.DataCase

  alias Mobilizon.Storage.Page
  alias Mobilizon.Users
  alias Mobilizon.Users.{Setting, User}
  import Mobilizon.Factory
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "users" do
    @valid_attrs %{email: "foo@bar.tld", password: "some password"}
    @update_attrs %{email: "foo@fighters.tld", password: "some updated password"}
    @invalid_attrs %{email: nil, password: nil}

    test "list_users/0 returns all users" do
      user = insert(:user)
      %Page{elements: users, total: 1} = Users.list_users("", nil, nil, :id, :desc)
      assert [user.id] == users |> Enum.map(& &1.id)
    end

    test "get_user!/1 returns the user with given id" do
      %User{id: user_id} = user = insert(:user)
      assert user == Users.get_user!(user_id)
    end

    # There's no create_user/1, just register/1
    test "register/1 with valid data creates a user" do
      assert {:ok, %User{email: email}} = Users.register(@valid_attrs)

      assert email == @valid_attrs.email
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error,
              %Ecto.Changeset{
                errors: [
                  password: {"can't be blank", [validation: :required]},
                  email: {"can't be blank", [validation: :required]}
                ],
                valid?: false
              }} = Users.register(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      assert {:ok, %User{email: email}} = Users.update_user(user, @update_attrs)
      assert email == "foo@fighters.tld"
    end

    test "update_user/2 with invalid data returns error changeset" do
      %User{id: user_id} = user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
      assert user == Users.get_user!(user_id)
    end

    test "delete_user/1 empties the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Users.delete_user(user)
      assert Users.get_user(user.id).disabled == true
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Users.delete_user(user, reserve_email: false)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    @email "email@domain.tld"
    @password "password"

    test "get_user_by_email/1 finds an user by its email" do
      {:ok, %User{email: email} = user} = Users.register(%{email: @email, password: @password})

      assert email == @email
      {:ok, %User{id: id}} = Users.get_user_by_email(@email)
      assert id == user.id
      assert {:error, :user_not_found} = Users.get_user_by_email("no email")
    end

    test "get_user_by_email/1 finds an activated user by its email" do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      {:ok, %User{id: id}} = Users.get_user_by_email(@email, activated: false)
      assert id == user.id
      assert {:error, :user_not_found} = Users.get_user_by_email(@email, activated: true)

      Users.update_user(user, %{
        "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
        "confirmation_sent_at" => nil,
        "confirmation_token" => nil
      })

      assert {:error, :user_not_found} = Users.get_user_by_email(@email, activated: false)
      {:ok, %User{id: id}} = Users.get_user_by_email(@email, activated: true)
      assert id == user.id
    end

    @unconfirmed_email "unconfirmed@email.com"
    test "get_user_by_email/1 finds an user by its pending email" do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      Users.update_user(user, %{
        "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
        "confirmation_sent_at" => nil,
        "confirmation_token" => nil
      })

      assert {:ok, %User{}} = Users.update_user_email(user, @unconfirmed_email)

      assert {:error, :user_not_found} =
               Users.get_user_by_email(@unconfirmed_email, unconfirmed: false)

      assert {:ok, %User{}} = Users.get_user_by_email(@unconfirmed_email, unconfirmed: true)
    end
  end

  describe "user_settings" do
    @valid_attrs %{timezone: "Europe/Paris", notification_each_week: true}
    @update_attrs %{timezone: "Atlantic/Cape_Verde", notification_each_week: false}
    @invalid_attrs %{timezone: nil, notification_each_week: nil}

    def setting_fixture(attrs \\ %{}) do
      {:ok, setting} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Users.create_setting()

      setting
    end

    test "create_setting/1 with valid data creates a setting" do
      %User{id: user_id} = insert(:user)

      assert {:ok, %Setting{} = setting} =
               Users.create_setting(Map.put(@valid_attrs, :user_id, user_id))

      assert setting.timezone == "Europe/Paris"
      assert setting.notification_each_week == true
    end

    test "create_setting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_setting(@invalid_attrs)
    end

    test "update_setting/2 with valid data updates the setting" do
      %User{id: user_id} = insert(:user)
      setting = setting_fixture(user_id: user_id)
      assert {:ok, %Setting{} = setting} = Users.update_setting(setting, @update_attrs)
      assert setting.timezone == "Atlantic/Cape_Verde"
      assert setting.notification_each_week == false
    end
  end
end
