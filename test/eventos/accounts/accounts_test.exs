defmodule Eventos.AccountsTest do
  use Eventos.DataCase

  alias Eventos.Accounts

  describe "users" do
    alias Eventos.Accounts.User

    @valid_attrs %{email: "some email", password_hash: "some password_hash", role: 42, username: "some username"}
    @update_attrs %{email: "some updated email", password_hash: "some updated password_hash", role: 43, username: "some updated username"}
    @invalid_attrs %{email: nil, password_hash: nil, role: nil, username: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.password_hash == "some password_hash"
      assert user.role == 42
      assert user.username == "some username"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "some updated email"
      assert user.password_hash == "some updated password_hash"
      assert user.role == 43
      assert user.username == "some updated username"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "accounts" do
    alias Eventos.Accounts.Account

    @valid_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
    @update_attrs %{description: "some updated description", display_name: "some updated display_name", domain: "some updated domain", private_key: "some updated private_key", public_key: "some updated public_key", suspended: false, uri: "some updated uri", url: "some updated url", username: "some updated username"}
    @invalid_attrs %{description: nil, display_name: nil, domain: nil, private_key: nil, public_key: nil, suspended: nil, uri: nil, url: nil, username: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_account()

      account
    end

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.description == "some description"
      assert account.display_name == "some display_name"
      assert account.domain == "some domain"
      assert account.private_key == "some private_key"
      assert account.public_key == "some public_key"
      assert account.suspended == true
      assert account.uri == "some uri"
      assert account.url == "some url"
      assert account.username == "some username"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      assert {:ok, account} = Accounts.update_account(account, @update_attrs)
      assert %Account{} = account
      assert account.description == "some updated description"
      assert account.display_name == "some updated display_name"
      assert account.domain == "some updated domain"
      assert account.private_key == "some updated private_key"
      assert account.public_key == "some updated public_key"
      assert account.suspended == false
      assert account.uri == "some updated uri"
      assert account.url == "some updated url"
      assert account.username == "some updated username"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end

  describe "groups" do
    alias Eventos.Accounts.Group

    @valid_attrs %{description: "some description", suspended: true, title: "some title", uri: "some uri", url: "some url"}
    @update_attrs %{description: "some updated description", suspended: false, title: "some updated title", uri: "some updated uri", url: "some updated url"}
    @invalid_attrs %{description: nil, suspended: nil, title: nil, uri: nil, url: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Accounts.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Accounts.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = Accounts.create_group(@valid_attrs)
      assert group.description == "some description"
      assert group.suspended == true
      assert group.title == "some title"
      assert group.uri == "some uri"
      assert group.url == "some url"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, group} = Accounts.update_group(group, @update_attrs)
      assert %Group{} = group
      assert group.description == "some updated description"
      assert group.suspended == false
      assert group.title == "some updated title"
      assert group.uri == "some updated uri"
      assert group.url == "some updated url"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_group(group, @invalid_attrs)
      assert group == Accounts.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = Accounts.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = Accounts.change_group(group)
    end
  end

  describe "group_accounts" do
    alias Eventos.Accounts.GroupAccount

    @valid_attrs %{role: 42}
    @update_attrs %{role: 43}
    @invalid_attrs %{role: nil}

    def group_account_fixture(attrs \\ %{}) do
      {:ok, group_account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_group_account()

      group_account
    end

    test "list_group_accounts/0 returns all group_accounts" do
      group_account = group_account_fixture()
      assert Accounts.list_group_accounts() == [group_account]
    end

    test "get_group_account!/1 returns the group_account with given id" do
      group_account = group_account_fixture()
      assert Accounts.get_group_account!(group_account.id) == group_account
    end

    test "create_group_account/1 with valid data creates a group_account" do
      assert {:ok, %GroupAccount{} = group_account} = Accounts.create_group_account(@valid_attrs)
      assert group_account.role == 42
    end

    test "create_group_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_group_account(@invalid_attrs)
    end

    test "update_group_account/2 with valid data updates the group_account" do
      group_account = group_account_fixture()
      assert {:ok, group_account} = Accounts.update_group_account(group_account, @update_attrs)
      assert %GroupAccount{} = group_account
      assert group_account.role == 43
    end

    test "update_group_account/2 with invalid data returns error changeset" do
      group_account = group_account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_group_account(group_account, @invalid_attrs)
      assert group_account == Accounts.get_group_account!(group_account.id)
    end

    test "delete_group_account/1 deletes the group_account" do
      group_account = group_account_fixture()
      assert {:ok, %GroupAccount{}} = Accounts.delete_group_account(group_account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_group_account!(group_account.id) end
    end

    test "change_group_account/1 returns a group_account changeset" do
      group_account = group_account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_group_account(group_account)
    end
  end

  describe "group_request" do
    alias Eventos.Accounts.GroupRequest

    @valid_attrs %{state: 42}
    @update_attrs %{state: 43}
    @invalid_attrs %{state: nil}

    def group_request_fixture(attrs \\ %{}) do
      {:ok, group_request} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_group_request()

      group_request
    end

    test "list_group_requests/0 returns all group_request" do
      group_request = group_request_fixture()
      assert Accounts.list_group_requests() == [group_request]
    end

    test "get_group_request!/1 returns the group_request with given id" do
      group_request = group_request_fixture()
      assert Accounts.get_group_request!(group_request.id) == group_request
    end

    test "create_group_request/1 with valid data creates a group_request" do
      assert {:ok, %GroupRequest{} = group_request} = Accounts.create_group_request(@valid_attrs)
      assert group_request.state == 42
    end

    test "create_group_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_group_request(@invalid_attrs)
    end

    test "update_group_request/2 with valid data updates the group_request" do
      group_request = group_request_fixture()
      assert {:ok, group_request} = Accounts.update_group_request(group_request, @update_attrs)
      assert %GroupRequest{} = group_request
      assert group_request.state == 43
    end

    test "update_group_request/2 with invalid data returns error changeset" do
      group_request = group_request_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_group_request(group_request, @invalid_attrs)
      assert group_request == Accounts.get_group_request!(group_request.id)
    end

    test "delete_group_request/1 deletes the group_request" do
      group_request = group_request_fixture()
      assert {:ok, %GroupRequest{}} = Accounts.delete_group_request(group_request)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_group_request!(group_request.id) end
    end

    test "change_group_request/1 returns a group_request changeset" do
      group_request = group_request_fixture()
      assert %Ecto.Changeset{} = Accounts.change_group_request(group_request)
    end
  end
end
