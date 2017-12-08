defmodule Eventos.EventsTest do
  use Eventos.DataCase

  alias Eventos.Events

  describe "events" do
    alias Eventos.Events.Event

    @valid_attrs %{begin_on: "2010-04-17 14:00:00.000000Z", description: "some description", ends_on: "2010-04-17 14:00:00.000000Z", title: "some title"}
    @update_attrs %{begin_on: "2011-05-18 15:01:01.000000Z", description: "some updated description", ends_on: "2011-05-18 15:01:01.000000Z", title: "some updated title"}
    @invalid_attrs %{begin_on: nil, description: nil, ends_on: nil, title: nil}

    def event_fixture(attrs \\ %{}) do
      {:ok, event} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event()

      event
    end

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      assert {:ok, %Event{} = event} = Events.create_event(@valid_attrs)
      assert event.begin_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.description == "some description"
      assert event.ends_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.title == "some title"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      assert {:ok, event} = Events.update_event(event, @update_attrs)
      assert %Event{} = event
      assert event.begin_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.description == "some updated description"
      assert event.ends_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.title == "some updated title"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end

  describe "categories" do
    alias Eventos.Events.Category

    @valid_attrs %{picture: "some picture", title: "some title"}
    @update_attrs %{picture: "some updated picture", title: "some updated title"}
    @invalid_attrs %{picture: nil, title: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Events.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Events.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Events.create_category(@valid_attrs)
      assert category.picture == "some picture"
      assert category.title == "some title"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, category} = Events.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.picture == "some updated picture"
      assert category.title == "some updated title"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_category(category, @invalid_attrs)
      assert category == Events.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Events.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Events.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Events.change_category(category)
    end
  end

  describe "tags" do
    alias Eventos.Events.Tag

    @valid_attrs %{slug: "some slug", title: "some title"}
    @update_attrs %{slug: "some updated slug", title: "some updated title"}
    @invalid_attrs %{slug: nil, title: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Events.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Events.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Events.create_tag(@valid_attrs)
      assert tag.slug == "some slug"
      assert tag.title == "some title"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, tag} = Events.update_tag(tag, @update_attrs)
      assert %Tag{} = tag
      assert tag.slug == "some updated slug"
      assert tag.title == "some updated title"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_tag(tag, @invalid_attrs)
      assert tag == Events.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Events.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Events.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Events.change_tag(tag)
    end
  end

  describe "event_accounts" do
    alias Eventos.Events.EventAccounts

    @valid_attrs %{roles: 42}
    @update_attrs %{roles: 43}
    @invalid_attrs %{roles: nil}

    def event_accounts_fixture(attrs \\ %{}) do
      {:ok, event_accounts} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event_accounts()

      event_accounts
    end

    test "list_event_accounts/0 returns all event_accounts" do
      event_accounts = event_accounts_fixture()
      assert Events.list_event_accounts() == [event_accounts]
    end

    test "get_event_accounts!/1 returns the event_accounts with given id" do
      event_accounts = event_accounts_fixture()
      assert Events.get_event_accounts!(event_accounts.id) == event_accounts
    end

    test "create_event_accounts/1 with valid data creates a event_accounts" do
      assert {:ok, %EventAccounts{} = event_accounts} = Events.create_event_accounts(@valid_attrs)
      assert event_accounts.roles == 42
    end

    test "create_event_accounts/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event_accounts(@invalid_attrs)
    end

    test "update_event_accounts/2 with valid data updates the event_accounts" do
      event_accounts = event_accounts_fixture()
      assert {:ok, event_accounts} = Events.update_event_accounts(event_accounts, @update_attrs)
      assert %EventAccounts{} = event_accounts
      assert event_accounts.roles == 43
    end

    test "update_event_accounts/2 with invalid data returns error changeset" do
      event_accounts = event_accounts_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event_accounts(event_accounts, @invalid_attrs)
      assert event_accounts == Events.get_event_accounts!(event_accounts.id)
    end

    test "delete_event_accounts/1 deletes the event_accounts" do
      event_accounts = event_accounts_fixture()
      assert {:ok, %EventAccounts{}} = Events.delete_event_accounts(event_accounts)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event_accounts!(event_accounts.id) end
    end

    test "change_event_accounts/1 returns a event_accounts changeset" do
      event_accounts = event_accounts_fixture()
      assert %Ecto.Changeset{} = Events.change_event_accounts(event_accounts)
    end
  end

  describe "event_requests" do
    alias Eventos.Events.EventRequest

    @valid_attrs %{state: 42}
    @update_attrs %{state: 43}
    @invalid_attrs %{state: nil}

    def event_request_fixture(attrs \\ %{}) do
      {:ok, event_request} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event_request()

      event_request
    end

    test "list_event_requests/0 returns all event_requests" do
      event_request = event_request_fixture()
      assert Events.list_event_requests() == [event_request]
    end

    test "get_event_request!/1 returns the event_request with given id" do
      event_request = event_request_fixture()
      assert Events.get_event_request!(event_request.id) == event_request
    end

    test "create_event_request/1 with valid data creates a event_request" do
      assert {:ok, %EventRequest{} = event_request} = Events.create_event_request(@valid_attrs)
      assert event_request.state == 42
    end

    test "create_event_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event_request(@invalid_attrs)
    end

    test "update_event_request/2 with valid data updates the event_request" do
      event_request = event_request_fixture()
      assert {:ok, event_request} = Events.update_event_request(event_request, @update_attrs)
      assert %EventRequest{} = event_request
      assert event_request.state == 43
    end

    test "update_event_request/2 with invalid data returns error changeset" do
      event_request = event_request_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event_request(event_request, @invalid_attrs)
      assert event_request == Events.get_event_request!(event_request.id)
    end

    test "delete_event_request/1 deletes the event_request" do
      event_request = event_request_fixture()
      assert {:ok, %EventRequest{}} = Events.delete_event_request(event_request)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event_request!(event_request.id) end
    end

    test "change_event_request/1 returns a event_request changeset" do
      event_request = event_request_fixture()
      assert %Ecto.Changeset{} = Events.change_event_request(event_request)
    end
  end
end
