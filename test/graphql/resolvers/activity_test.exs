defmodule Mobilizon.GraphQL.Resolvers.ActivityTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.{Activities, Posts}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Event, as: EventActivity
  alias Mobilizon.Service.Activity.Post, as: PostActivity

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    group = insert(:group)
    {:ok, conn: conn, group: group}
  end

  describe "Resolver: List activities for group" do
    @group_activities_query """
    query GroupTimeline(
    $preferredUsername: String!
    $type: ActivityType
    $page: Int
    $limit: Int
    ) {
    group(preferredUsername: $preferredUsername) {
      id
      preferredUsername
      domain
      name
      activity(type: $type, page: $page, limit: $limit) {
        total
        elements {
          id
          insertedAt
          subject
          subjectParams {
            key
            value
          }
          type
          author {
            id
            preferredUsername
            name
            domain
            avatar {
              id
              url
            }
          }
          group {
            id
            preferredUsername
          }
          object {
            ... on Event {
              id
              title
            }
            ... on Post {
              id
              title
            }
            ... on Member {
              id
              actor {
                id
                name
                preferredUsername
                domain
                avatar {
                  id
                  url
                }
              }
            }
            ... on Resource {
              id
              title
              path
              type
            }
            ... on Discussion {
              id
              title
              slug
            }
            ... on Group {
              id
              preferredUsername
              domain
              name
              summary
              visibility
              openness
              physicalAddress {
                id
              }
              banner {
                id
              }
              avatar {
                id
              }
            }
          }
        }
      }
    }
    }
    """

    test "without being logged-in", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username}
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @group_activities_query,
          variables: %{preferredUsername: preferred_username}
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
          query: @group_activities_query,
          variables: %{preferredUsername: preferred_username}
        )

      assert hd(res["errors"])["message"] == "unauthorized"
    end

    test "without being a validated member", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username} = group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: actor, role: :not_approved)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_activities_query,
          variables: %{preferredUsername: preferred_username}
        )

      assert hd(res["errors"])["message"] == "unauthorized"
    end

    test "group_activity/3 list group activities", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username, id: group_id} = group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)

      insert(:member,
        parent: group,
        actor: actor,
        role: :member,
        member_since: DateTime.truncate(DateTime.utc_now(), :second)
      )

      event = insert(:event, attributed_to: group, organizer_actor: actor)
      EventActivity.insert_activity(event, subject: "event_created")
      assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :activity)
      assert Activities.list_activities() |> length() == 1

      [%Activity{author_id: author_id, group_id: activity_group_id}] =
        Activities.list_activities()

      assert author_id == actor.id
      assert activity_group_id == group_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_activities_query,
          variables: %{preferredUsername: preferred_username}
        )

      assert res["errors"] == nil
      assert res["data"]["group"]["id"] == to_string(group_id)
      assert res["data"]["group"]["activity"]["total"] == 1
      activity = hd(res["data"]["group"]["activity"]["elements"])
      assert activity["object"]["id"] == to_string(event.id)
      assert activity["subject"] == "event_created"

      assert Enum.find(activity["subjectParams"], &(&1["key"] == "event_title"))["value"] ==
               event.title

      assert Enum.find(activity["subjectParams"], &(&1["key"] == "event_uuid"))["value"] ==
               event.uuid
    end

    test "group_activity/3 list group activities from deleted object", %{
      conn: conn,
      group: %Actor{preferred_username: preferred_username, id: group_id} = group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)

      insert(:member,
        parent: group,
        actor: actor,
        role: :member,
        member_since: DateTime.truncate(DateTime.utc_now(), :second)
      )

      post = insert(:post, attributed_to: group, author: actor)
      PostActivity.insert_activity(post, subject: "post_created")
      Process.sleep(1000)
      Posts.delete_post(post)
      PostActivity.insert_activity(post, subject: "post_deleted")
      assert %{success: 2, failure: 0} == Oban.drain_queue(queue: :activity)
      assert Activities.list_activities() |> length() == 2

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @group_activities_query,
          variables: %{preferredUsername: preferred_username}
        )

      assert res["errors"] == nil
      assert res["data"]["group"]["id"] == to_string(group_id)
      assert res["data"]["group"]["activity"]["total"] == 2
      [delete_activity, create_activity] = res["data"]["group"]["activity"]["elements"]
      assert create_activity["object"] == nil
      assert create_activity["subject"] == "post_created"

      assert Enum.find(create_activity["subjectParams"], &(&1["key"] == "post_title"))["value"] ==
               post.title

      assert Enum.find(create_activity["subjectParams"], &(&1["key"] == "post_slug"))["value"] ==
               post.slug

      assert delete_activity["object"] == nil
      assert delete_activity["subject"] == "post_deleted"
    end
  end
end
