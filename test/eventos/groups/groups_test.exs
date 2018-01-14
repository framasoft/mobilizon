defmodule Eventos.GroupsTest do
  use Eventos.DataCase

  alias Eventos.Groups

  describe "groups" do
    alias Eventos.Groups.Group

    @valid_attrs %{description: "some description", suspended: true, title: "some title", uri: "some uri", url: "some url"}
    @update_attrs %{description: "some updated description", suspended: false, title: "some updated title", uri: "some updated uri", url: "some updated url"}
    @invalid_attrs %{description: nil, suspended: nil, title: nil, uri: nil, url: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Groups.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Groups.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Groups.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = Groups.create_group(@valid_attrs)
      assert group.description == "some description"
      assert group.suspended
      assert group.title == "some title"
      assert group.uri == "some uri"
      assert group.url == "some url"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, group} = Groups.update_group(group, @update_attrs)
      assert %Group{} = group
      assert group.description == "some updated description"
      refute group.suspended
      assert group.title == "some updated title"
      assert group.uri == "some updated uri"
      assert group.url == "some updated url"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = Groups.update_group(group, @invalid_attrs)
      assert group == Groups.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = Groups.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = Groups.change_group(group)
    end
  end
#
#  describe "members" do
#    alias Eventos.Groups.Member
#
#    @valid_attrs %{role: 42}
#    @update_attrs %{role: 43}
#    @invalid_attrs %{role: nil}
#
#    def member_fixture(attrs \\ %{}) do
#      {:ok, member} =
#        attrs
#        |> Enum.into(@valid_attrs)
#        |> Groups.create_member()
#
#      member
#    end
#
#    test "list_members/0 returns all members" do
#      member = member_fixture()
#      assert Groups.list_members() == [member]
#    end
#
#    test "get_member!/1 returns the member with given id" do
#      member = member_fixture()
#      assert Groups.get_member!(member.id) == member
#    end
#
#    test "create_member/1 with valid data creates a member" do
#      assert {:ok, %Member{} = member} = Groups.create_member(@valid_attrs)
#      assert member.role == 42
#    end
#
#    test "create_member/1 with invalid data returns error changeset" do
#      assert {:error, %Ecto.Changeset{}} = Groups.create_member(@invalid_attrs)
#    end
#
#    test "update_member/2 with valid data updates the member" do
#      member = member_fixture()
#      assert {:ok, member} = Groups.update_member(member, @update_attrs)
#      assert %Member{} = member
#      assert member.role == 43
#    end
#
#    test "update_member/2 with invalid data returns error changeset" do
#      member = member_fixture()
#      assert {:error, %Ecto.Changeset{}} = Groups.update_member(member, @invalid_attrs)
#      assert member == Groups.get_member!(member.id)
#    end
#
#    test "delete_member/1 deletes the member" do
#      member = member_fixture()
#      assert {:ok, %Member{}} = Groups.delete_member(member)
#      assert_raise Ecto.NoResultsError, fn -> Groups.get_member!(member.id) end
#    end
#
#    test "change_member/1 returns a member changeset" do
#      member = member_fixture()
#      assert %Ecto.Changeset{} = Groups.change_member(member)
#    end
#  end
#
#  describe "requests" do
#    alias Eventos.Groups.Request
#
#    @valid_attrs %{state: 42}
#    @update_attrs %{state: 43}
#    @invalid_attrs %{state: nil}
#
#    def request_fixture(attrs \\ %{}) do
#      {:ok, request} =
#        attrs
#        |> Enum.into(@valid_attrs)
#        |> Groups.create_request()
#
#      request
#    end
#
#    test "list_requests/0 returns all requests" do
#      request = request_fixture()
#      assert Groups.list_requests() == [request]
#    end
#
#    test "get_request!/1 returns the request with given id" do
#      request = request_fixture()
#      assert Groups.get_request!(request.id) == request
#    end
#
#    test "create_request/1 with valid data creates a request" do
#      assert {:ok, %Request{} = request} = Groups.create_request(@valid_attrs)
#      assert request.state == 42
#    end
#
#    test "create_request/1 with invalid data returns error changeset" do
#      assert {:error, %Ecto.Changeset{}} = Groups.create_request(@invalid_attrs)
#    end
#
#    test "update_request/2 with valid data updates the request" do
#      request = request_fixture()
#      assert {:ok, request} = Groups.update_request(request, @update_attrs)
#      assert %Request{} = request
#      assert request.state == 43
#    end
#
#    test "update_request/2 with invalid data returns error changeset" do
#      request = request_fixture()
#      assert {:error, %Ecto.Changeset{}} = Groups.update_request(request, @invalid_attrs)
#      assert request == Groups.get_request!(request.id)
#    end
#
#    test "delete_request/1 deletes the request" do
#      request = request_fixture()
#      assert {:ok, %Request{}} = Groups.delete_request(request)
#      assert_raise Ecto.NoResultsError, fn -> Groups.get_request!(request.id) end
#    end
#
#    test "change_request/1 returns a request changeset" do
#      request = request_fixture()
#      assert %Ecto.Changeset{} = Groups.change_request(request)
#    end
#  end
end
