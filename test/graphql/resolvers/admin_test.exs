defmodule Mobilizon.GraphQL.Resolvers.AdminTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias Mobilizon.Federation.ActivityPub.Relay

  alias Mobilizon.GraphQL.{AbsintheHelpers, API}

  describe "Resolver: List the action logs" do
    @note_content "This a note on a report"
    test "list_action_logs/3 list action logs", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = moderator = insert(:actor, user: user_moderator)

      %User{} = user_moderator_2 = insert(:user, role: :moderator)
      %Actor{} = moderator_2 = insert(:actor, user: user_moderator_2)

      %Report{} = report = insert(:report)
      API.Reports.update_report_status(moderator, report, "resolved")

      {:ok, %Note{} = note} = API.Reports.create_report_note(report, moderator_2, @note_content)

      API.Reports.delete_report_note(note, moderator_2)

      query = """
      {
        actionLogs {
          total
          elements {
            action,
            actor {
              preferredUsername
            },
            object {
              ... on Report {
                id,
                status
              },
              ... on ReportNote {
                content
              }
            }
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and a moderator to list action logs"

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["actionLogs"]["total"] == 3
      assert json_response(res, 200)["data"]["actionLogs"]["elements"] |> length == 3

      assert json_response(res, 200)["data"]["actionLogs"]["elements"] == [
               %{
                 "action" => "NOTE_DELETION",
                 "actor" => %{"preferredUsername" => moderator_2.preferred_username},
                 "object" => %{"content" => @note_content}
               },
               %{
                 "action" => "NOTE_CREATION",
                 "actor" => %{"preferredUsername" => moderator_2.preferred_username},
                 "object" => %{"content" => @note_content}
               },
               %{
                 "action" => "REPORT_UPDATE_RESOLVED",
                 "actor" => %{"preferredUsername" => moderator.preferred_username},
                 "object" => %{"id" => to_string(report.id), "status" => "RESOLVED"}
               }
             ]
    end
  end

  describe "Resolver: Get the dashboard statistics" do
    test "get_dashboard/3 gets dashboard information", %{conn: conn} do
      %Event{title: title} = insert(:event)

      %User{} = user_admin = insert(:user, role: :administrator)

      query = """
      {
        dashboard {
          lastPublicEventPublished {
            title
          }
          numberOfUsers,
          numberOfComments,
          numberOfEvents,
          numberOfReports
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and an administrator to access dashboard statistics"

      res =
        conn
        |> auth_conn(user_admin)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["dashboard"]["lastPublicEventPublished"]["title"] ==
               title
    end
  end

  describe "Resolver: Get the list of relay followers" do
    @relay_followers_query """
    {
      relayFollowers {
        elements {
          actor {
            preferredUsername,
            domain,
          },
          approved
        },
        total
      }
    }
    """

    @relay_followings_query """
    {
        relayFollowings {
          elements {
            targetActor {
              preferredUsername,
              domain,
            },
            approved
          },
          total
        }
      }
    """

    test "test list_relay_followers/3 returns nothing when not logged-in", %{conn: conn} do
      follower_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: follower_actor, target_actor: relay_actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @relay_followers_query)

      assert hd(res["errors"])["message"] == "You need to be logged in"
      assert hd(res["errors"])["status_code"] == 401
    end

    test "test list_relay_followers/3 returns nothing when not an admin", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %User{} = user = insert(:user)

      follower_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: follower_actor, target_actor: relay_actor)

      res =
        conn
        |> auth_conn(user_moderator)
        |> AbsintheHelpers.graphql_query(query: @relay_followers_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
      assert hd(res["errors"])["status_code"] == 403

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @relay_followers_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
      assert hd(res["errors"])["status_code"] == 403
    end

    test "test list_relay_followers/3 returns relay followers", %{conn: conn} do
      %User{} = user_admin = insert(:user, role: :administrator)

      follower_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: follower_actor, target_actor: relay_actor)

      res =
        conn
        |> auth_conn(user_admin)
        |> AbsintheHelpers.graphql_query(query: @relay_followers_query)

      assert is_nil(res["errors"])

      assert hd(res["data"]["relayFollowers"]["elements"]) == %{
               "actor" => %{"preferredUsername" => "instance_actor", "domain" => "localhost"},
               "approved" => false
             }
    end

    test "test list_relay_followings/3 returns nothing when not logged-in", %{conn: conn} do
      %Actor{} =
        following_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: relay_actor, target_actor: following_actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @relay_followings_query)

      assert hd(res["errors"])["message"] == "You need to be logged in"
      assert hd(res["errors"])["status_code"] == 401
    end

    test "test list_relay_followings/3 returns nothing when not an admin", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %User{} = user = insert(:user)

      %Actor{} =
        following_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: relay_actor, target_actor: following_actor)

      res =
        conn
        |> auth_conn(user_moderator)
        |> AbsintheHelpers.graphql_query(query: @relay_followings_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
      assert hd(res["errors"])["status_code"] == 403

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @relay_followings_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
      assert hd(res["errors"])["status_code"] == 403
    end

    test "test list_relay_followings/3 returns relay followings", %{conn: conn} do
      %User{} = user_admin = insert(:user, role: :administrator)

      %Actor{
        preferred_username: following_actor_preferred_username,
        domain: following_actor_domain
      } =
        following_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Relay.get_actor()
      insert(:follower, actor: relay_actor, target_actor: following_actor)

      res =
        conn
        |> auth_conn(user_admin)
        |> AbsintheHelpers.graphql_query(query: @relay_followings_query)

      assert is_nil(res["errors"])

      assert hd(res["data"]["relayFollowings"]["elements"]) == %{
               "targetActor" => %{
                 "preferredUsername" => following_actor_preferred_username,
                 "domain" => following_actor_domain
               },
               "approved" => false
             }
    end
  end

  @admin_settings_fragment """
  fragment adminSettingsFragment on AdminSettings {
    instanceName
    instanceDescription
    instanceLongDescription
    contact
    instanceTerms
    instanceTermsType
    instanceTermsUrl
    instancePrivacyPolicy
    instancePrivacyPolicyType
    instancePrivacyPolicyUrl
    instanceRules
    registrationsOpen
  }
  """

  describe "Resolver: Get the instance admin settings" do
    @admin_settings_query """
    query {
      adminSettings {
        ...adminSettingsFragment
      }
    }
    #{@admin_settings_fragment}
    """

    setup %{conn: conn} do
      Cachex.clear(:config)
      [conn: conn]
    end

    test "from config files", %{conn: conn} do
      admin = insert(:user, role: :administrator)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(query: @admin_settings_query)

      assert res["data"]["adminSettings"]["instanceName"] ==
               Application.get_env(:mobilizon, :instance)[:name]

      assert res["data"]["adminSettings"]["registrationsOpen"] ==
               Application.get_env(:mobilizon, :instance)[:registrations_open]
    end

    @instance_name "My Awesome Instance"
    test "from DB", %{conn: conn} do
      admin = insert(:user, role: :administrator)
      insert(:admin_setting, group: "instance", name: "instance_name", value: @instance_name)
      insert(:admin_setting, group: "instance", name: "registrations_open", value: "false")

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(query: @admin_settings_query)

      assert res["data"]["adminSettings"]["instanceName"] == @instance_name

      assert res["data"]["adminSettings"]["registrationsOpen"] == false
    end

    test "unless user isn't admin", %{conn: conn} do
      admin = insert(:user)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(query: @admin_settings_query)

      assert hd(res["errors"])["message"] ==
               "You need to be logged-in and an administrator to access admin settings"
    end
  end

  describe "Resolver: Update the instance admin settings" do
    setup %{conn: conn} do
      Cachex.clear(:config)
      [conn: conn]
    end

    @update_instance_admin_settings_mutation """
    mutation SaveAdminSettings(
      $instanceName: String
      $instanceDescription: String
      $instanceLongDescription: String
      $contact: String
      $instanceTerms: String
      $instanceTermsType: InstanceTermsType
      $instanceTermsUrl: String
      $instancePrivacyPolicy: String
      $instancePrivacyPolicyType: InstancePrivacyType
      $instancePrivacyPolicyUrl: String
      $instanceRules: String
      $registrationsOpen: Boolean
      ) {
      saveAdminSettings(
        instanceName: $instanceName
        instanceDescription: $instanceDescription
        instanceLongDescription: $instanceLongDescription
        contact: $contact
        instanceTerms: $instanceTerms
        instanceTermsType: $instanceTermsType
        instanceTermsUrl: $instanceTermsUrl
        instancePrivacyPolicy: $instancePrivacyPolicy
        instancePrivacyPolicyType: $instancePrivacyPolicyType
        instancePrivacyPolicyUrl: $instancePrivacyPolicyUrl
        instanceRules: $instanceRules
        registrationsOpen: $registrationsOpen
      ) {
        ...adminSettingsFragment
      }
    }
    #{@admin_settings_fragment}
    """

    @new_instance_name "new Instance Name"

    test "does the setting update and updates instance actor as well", %{conn: conn} do
      admin = insert(:user, role: :administrator)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(query: @admin_settings_query)

      assert res["data"]["adminSettings"]["instanceName"] ==
               Application.get_env(:mobilizon, :instance)[:name]

      assert res["data"]["adminSettings"]["registrationsOpen"] ==
               Application.get_env(:mobilizon, :instance)[:registrations_open]

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @update_instance_admin_settings_mutation,
          variables: %{"instanceName" => @new_instance_name, "registrationsOpen" => false}
        )

      assert res["data"]["saveAdminSettings"]["instanceName"] == @new_instance_name
      assert res["data"]["saveAdminSettings"]["registrationsOpen"] == false

      assert %Actor{name: @new_instance_name} = Relay.get_actor()
    end

    test "unless user isn't admin", %{conn: conn} do
      admin = insert(:user)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @update_instance_admin_settings_mutation,
          variables: %{"instanceName" => @new_instance_name, "registrationsOpen" => false}
        )

      assert hd(res["errors"])["message"] ==
               "You need to be logged-in and an administrator to save admin settings"
    end
  end
end
