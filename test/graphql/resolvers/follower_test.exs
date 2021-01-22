defmodule Mobilizon.Web.Resolvers.FollowerTest do
  use Mobilizon.Web.ConnCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    group = insert(:group)
    insert(:member, parent: group, actor: actor, role: :moderator)
    follower = insert(:follower, target_actor: group)

    {:ok, conn: conn, actor: actor, user: user, group: group, follower: follower}
  end

  @group_followers_query """
  query(
    $name: String!
    $followersPage: Int
    $followersLimit: Int
    $approved: Boolean
  ) {
    group(preferredUsername: $name) {
      id
      preferredUsername
      name
      domain
      followers(
        page: $followersPage
        limit: $followersLimit
        approved: $approved
      ) {
        total
        elements {
          id
          actor {
            id
            preferredUsername
            name
            domain
            avatar {
              id
              url
            }
          }
          approved
          insertedAt
          updatedAt
        }
      }
    }
  }
  """

  describe "list group followers find_followers_for_group/3" do
    test "without being logged-in", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username}
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{name: preferred_username}
        )

      assert hd(res["errors"])["message"] == "unauthenticated"
    end

    test "without being a member", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username}
    } do
      user = insert(:user)
      insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{name: preferred_username}
        )

      assert hd(res["errors"])["message"] == "unauthorized"
    end

    test "without being a moderator", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username} = group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: actor, role: :member)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{name: preferred_username}
        )

      assert hd(res["errors"])["message"] == "unauthorized"
    end

    test "while being a moderator", %{
      conn: conn,
      user: user,
      group: %Actor{preferred_username: preferred_username, id: group_id} = group,
      follower: %Follower{id: follower_id}
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{name: preferred_username}
        )

      assert res["errors"] == nil
      assert res["data"]["group"]["id"] == to_string(group_id)
      assert res["data"]["group"]["followers"]["total"] == 1
      assert hd(res["data"]["group"]["followers"]["elements"])["id"] == to_string(follower_id)

      Process.sleep(1000)
      insert(:follower, target_actor: group)
      Process.sleep(1000)
      follower3 = insert(:follower, target_actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{
            name: preferred_username,
            followersLimit: 2,
            followersPage: 1
          }
        )

      assert res["errors"] == nil
      assert res["data"]["group"]["id"] == to_string(group_id)
      assert res["data"]["group"]["followers"]["total"] == 3
      assert hd(res["data"]["group"]["followers"]["elements"])["id"] == to_string(follower3.id)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_followers_query,
          variables: %{
            name: preferred_username,
            followersLimit: 2,
            followersPage: 2
          }
        )

      assert res["errors"] == nil
      assert res["data"]["group"]["id"] == to_string(group_id)
      assert res["data"]["group"]["followers"]["total"] == 3
      assert hd(res["data"]["group"]["followers"]["elements"])["id"] == to_string(follower_id)
    end
  end

  @update_follower_mutation """
  mutation UpdateFollower($id: ID!, $approved: Boolean) {
    updateFollower(id: $id, approved: $approved) {
      id
      approved
    }
  }
  """
  describe "update a follower update_follower/3" do
    test "without being logged-in", %{
      conn: conn,
      group: %Actor{} = group
    } do
      %Follower{id: follower_id} = insert(:follower, target_actor: group)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @update_follower_mutation,
          variables: %{id: follower_id, approved: true}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "without being a member", %{
      conn: conn,
      group: %Actor{} = group
    } do
      user = insert(:user)
      insert(:actor, user: user)
      %Follower{id: follower_id} = insert(:follower, target_actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_follower_mutation,
          variables: %{id: follower_id, approved: true}
        )

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
    end

    test "without being a moderator", %{
      conn: conn,
      group: %Actor{} = group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: actor, role: :member)
      %Follower{id: follower_id} = insert(:follower, target_actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_follower_mutation,
          variables: %{id: follower_id, approved: true}
        )

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
    end

    test "while being a moderator", %{
      conn: conn,
      user: user,
      follower: %Follower{id: follower_id, approved: false}
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_follower_mutation,
          variables: %{id: follower_id, approved: true}
        )

      assert res["errors"] == nil
      assert res["data"]["updateFollower"]["id"] == to_string(follower_id)

      assert %Follower{approved: true} = Actors.get_follower(follower_id)
    end

    test "reject deletes the follower", %{
      conn: conn,
      user: user,
      follower: %Follower{id: follower_id, approved: false}
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_follower_mutation,
          variables: %{id: follower_id, approved: false}
        )

      assert res["errors"] == nil
      assert res["data"]["updateFollower"]["id"] == to_string(follower_id)

      assert is_nil(Actors.get_follower(follower_id))
    end
  end
end
