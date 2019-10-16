defmodule Mobilizon.UsersTest do
  use Mobilizon.DataCase

  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import Mobilizon.Factory
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "users" do
    @valid_attrs %{email: "foo@bar.tld", password: "some password"}
    @update_attrs %{email: "foo@fighters.tld", password: "some updated password"}
    @invalid_attrs %{email: nil, password: nil}

    test "list_users/0 returns all users" do
      user = insert(:user)
      users = Users.list_users(nil, nil, :id, :desc)
      assert [user.id] == users |> Enum.map(& &1.id)
    end

    test "get_user!/1 returns the user with given id" do
      user = insert(:user)
      assert user = Users.get_user!(user.id)
    end

    # There's no create_user/1, just register/1
    test "register/1 with valid data creates a user" do
      assert {:ok, %User{email: email} = user} = Users.register(@valid_attrs)

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
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
      assert user = Users.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    # test "change_user/1 returns a user changeset" do
    #   user = insert(:user)
    #   assert %Ecto.Changeset{} = Users.change_user(user)
    # end

    @email "email@domain.tld"
    @password "password"
    test "authenticate/1 checks the user's password" do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      assert {:ok, _} = Users.authenticate(%{user: user, password: @password})

      assert {:error, :unauthorized} ==
               Users.authenticate(%{user: user, password: "bad password"})
    end

    test "get_user_by_email/1 finds an user by its email" do
      {:ok, %User{email: email} = user} = Users.register(%{email: @email, password: @password})

      assert email == @email
      {:ok, %User{id: id}} = Users.get_user_by_email(@email)
      assert id == user.id
      assert {:error, :user_not_found} = Users.get_user_by_email("no email")
    end

    test "get_user_by_email/1 finds an activated user by its email" do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      {:ok, %User{id: id}} = Users.get_user_by_email(@email, false)
      assert id == user.id
      assert {:error, :user_not_found} = Users.get_user_by_email(@email, true)

      Users.update_user(user, %{
        "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
        "confirmation_sent_at" => nil,
        "confirmation_token" => nil
      })

      assert {:error, :user_not_found} = Users.get_user_by_email(@email, false)
      {:ok, %User{id: id}} = Users.get_user_by_email(@email, true)
      assert id == user.id
    end
  end
end
