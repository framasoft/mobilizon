defmodule Mobilizon.GraphQL.Resolvers.AdminTest do
  use Mobilizon.Web.ConnCase
  import Mobilizon.Factory
  import Swoosh.TestAssertions

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.{AbsintheHelpers, API}

  describe "Resolver: List the action logs" do
    @action_logs_query """
    query ActionLogs {
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
      res = AbsintheHelpers.graphql_query(conn, query: @action_logs_query)

      assert res["errors"] |> hd |> Map.get("message") ==
               "You need to be logged in"

      res =
        conn
        |> auth_conn(user_moderator)
        |> AbsintheHelpers.graphql_query(query: @action_logs_query)

      assert is_nil(res["errors"])

      assert res["data"]["actionLogs"]["total"] == 3
      assert res["data"]["actionLogs"]["elements"] |> length == 3

      assert res["data"]["actionLogs"]["elements"] == [
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
    @dashbord_information_query """
      query Dashboard {
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

    test "get_dashboard/3 gets dashboard information", %{conn: conn} do
      %Event{title: title} = insert(:event)

      %User{} = user_admin = insert(:user, role: :administrator)

      res = AbsintheHelpers.graphql_query(conn, query: @dashbord_information_query)

      assert res["errors"] |> hd |> Map.get("message") == "You need to be logged in"

      res =
        conn
        |> auth_conn(user_admin)
        |> AbsintheHelpers.graphql_query(query: @dashbord_information_query)

      assert is_nil(res["errors"])

      assert title == res["data"]["dashboard"]["lastPublicEventPublished"]["title"]
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

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @relay_followers_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
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

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @relay_followings_query)

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
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
      on_exit(fn -> Cachex.clear(:config) end)
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
               "You don't have permission to do this"
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
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_instance_admin_settings_mutation,
          variables: %{"instanceName" => @new_instance_name, "registrationsOpen" => false}
        )

      assert hd(res["errors"])["message"] ==
               "You don't have permission to do this"
    end
  end

  @admin_update_user """
  mutation AdminUpdateUser($id: ID!, $email: String, $role: UserRole, $confirmed: Boolean, $notify: Boolean) {
    adminUpdateUser(id: $id, email: $email, role: $role, confirmed: $confirmed, notify: $notify) {
      id
      email
      role
      confirmedAt
    }
  }
  """

  describe "Resolver: Update an user email" do
    setup do
      admin = insert(:user, role: :administrator)
      user = insert(:user)
      {:ok, admin: admin, user: user}
    end

    test "when not an admin", %{conn: conn, user: user} do
      admin = insert(:user)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "email" => "new@email.com"}
        )

      assert hd(res["errors"])["message"] ==
               "You don't have permission to do this"
    end

    test "when putting same email", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "email" => user.email}
        )

      assert hd(res["errors"])["message"] ==
               "The new email must be different"
    end

    test "with an invalid email", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "email" => "not an email"}
        )

      assert hd(res["errors"])["message"] ==
               "The new email doesn't seem to be valid"
    end

    test "with a valid email, and no notification", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "email" => "new@email.com", "notify" => false}
        )

      refute_email_sent()

      assert res["errors"] == nil
      assert res["data"]["adminUpdateUser"]["email"] == "new@email.com"
    end

    test "with a valid email, and notification", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "email" => "new@email.com", "notify" => true}
        )

      assert_email_sent(
        to: user.email,
        subject:
          "An administrator manually changed the email attached to your account on #{Config.instance_name()}"
      )

      # # Swoosh.TestAssertions can't test multiple emails sent
      # assert_email_sent(
      #   to: "new@email.com",
      #   subject:
      #     "An administrator manually changed the email attached to your account on Test instance"
      # )

      assert res["errors"] == nil
      assert res["data"]["adminUpdateUser"]["email"] == "new@email.com"
    end
  end

  describe "Resolver: Update an user role" do
    setup do
      admin = insert(:user, role: :administrator)
      user = insert(:user)
      {:ok, admin: admin, user: user}
    end

    test "when putting same role", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "role" => String.upcase(to_string(user.role))}
        )

      assert hd(res["errors"])["message"] ==
               "The new role must be different"
    end

    test "with an invalid role", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "role" => "not a valid role"}
        )

      assert hd(res["errors"])["message"] ==
               "Argument \"role\" has invalid value $role."
    end

    test "with a valid role, and no notification", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "role" => "MODERATOR", "notify" => false}
        )

      refute_email_sent()

      assert res["errors"] == nil
      assert res["data"]["adminUpdateUser"]["role"] == "MODERATOR"
    end

    test "with a valid role, and notification", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "role" => "MODERATOR", "notify" => true}
        )

      assert_email_sent(to: user.email)

      assert res["errors"] == nil
      assert res["data"]["adminUpdateUser"]["role"] == "MODERATOR"
    end
  end

  describe "Resolver: Confirm an user" do
    setup do
      admin = insert(:user, role: :administrator)
      user = insert(:user)
      {:ok, admin: admin, user: user}
    end

    test "already confirmed", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "confirmed" => true, "notify" => false}
        )

      refute_email_sent()

      assert hd(res["errors"])["message"] == "Can't confirm an already confirmed user"
    end

    test "while unconfirming", %{conn: conn, user: user, admin: admin} do
      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "confirmed" => false, "notify" => false}
        )

      refute_email_sent()

      assert hd(res["errors"])["message"] == "Deconfirming users is not supported"
    end

    test "while confirming, and no notification", %{conn: conn, admin: admin} do
      user = insert(:user, confirmed_at: nil)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "confirmed" => true, "notify" => false}
        )

      refute_email_sent()

      assert res["errors"] == nil
      refute res["data"]["adminUpdateUser"]["confirmedAt"] == nil
    end

    test "while confirming, and notification", %{conn: conn, admin: admin} do
      user = insert(:user, confirmed_at: nil)

      res =
        conn
        |> auth_conn(admin)
        |> AbsintheHelpers.graphql_query(
          query: @admin_update_user,
          variables: %{"id" => user.id, "confirmed" => true, "notify" => true}
        )

      assert_email_sent(to: user.email)

      assert res["errors"] == nil
      refute res["data"]["adminUpdateUser"]["confirmedAt"] == nil
    end
  end
end
