defmodule Eventos.AccountsTest do
  use Eventos.DataCase

  alias Eventos.Accounts

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

  describe "users" do
    alias Eventos.Accounts.{User, Account}

    @account_valid_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
    @valid_attrs %{email: "foo@bar.tld", password_hash: "some password_hash", role: 42}
    @update_attrs %{email: "foo@fighters.tld", password_hash: "some updated password_hash", role: 43}
    @invalid_attrs %{email: nil, password_hash: nil, role: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@account_valid_attrs)
        |> Accounts.create_account()
      valid_attrs_with_account_id = Map.put(@valid_attrs, :account_id, account.id)
      {:ok, user} =
        attrs
        |> Enum.into(valid_attrs_with_account_id)
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
      {:ok, %Account{} = account} = Accounts.create_account(@account_valid_attrs)
      attrs = Map.put(@valid_attrs, :account_id, account.id)
      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "foo@bar.tld"
      assert user.password_hash == "some password_hash"
      assert user.role == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "foo@fighters.tld"
      assert user.password_hash == "some updated password_hash"
      assert user.role == 43
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
end
