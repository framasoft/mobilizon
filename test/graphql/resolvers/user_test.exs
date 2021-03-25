defmodule Mobilizon.GraphQL.Resolvers.UserTest do
  use Mobilizon.Web.ConnCase
  use Bamboo.Test
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory

  alias Mobilizon.{Actors, Config, Discussions, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Email

  @get_user_query """
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      email
    }
  }
  """

  @logged_user_query """
  query LoggedUser {
    loggedUser {
      id
      email
    }
  }
  """

  @list_users_query """
  query ListUsers($page: Int, $limit: Int, $sort: SortableUserField, $direction: SortDirection) {
    users(page: $page, limit: $limit, sort: $sort, direction: $direction) {
      total,
      elements {
        email
      }
    }
  }
  """

  @create_user_mutation """
  mutation CreateUser($email: String!, $password: String!, $locale: String) {
    createUser(
      email: $email
      password: $password
      locale: $locale
  ) {
      id,
      email,
      locale
    }
  }
  """

  @register_person_mutation """
  mutation RegisterPerson($preferredUsername: String!, $name: String, $summary: String, $email: String!) {
    registerPerson(
      preferredUsername: $preferredUsername,
      name: $name,
      summary: $summary,
      email: $email,
      ) {
        preferredUsername,
        name,
        summary,
        avatar {
          url
        },
      }
    }
  """

  @change_email_mutation """
      mutation ChangeEmail($email: String!, $password: String!) {
        changeEmail(email: $email, password: $password) {
            id
          }
        }
  """

  @login_mutation """
      mutation Login($email: String!, $password: String!) {
        login(email: $email, password: $password) {
            accessToken,
            refreshToken,
            user {
              id
            }
          }
        }
  """

  @validate_email_mutation """
      mutation ValidateEmail($token: String!) {
        validateEmail(
              token: $token
          ) {
            id
          }
        }
  """

  @send_reset_password_mutation """
    mutation SendResetPassword($email: String!) {
      sendResetPassword(email: $email)
    }
  """

  @delete_user_account_mutation """
    mutation DeleteAccount($password: String) {
      deleteAccount (password: $password) {
        id
      }
    }
  """

  @change_default_actor """
  mutation ChangeDefaultActor($preferredUsername: String!) {
    changeDefaultActor(preferredUsername: $preferredUsername) {
        defaultActor {
          preferredUsername
        }
      }
    }
  """

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
  @valid_single_actor_params %{preferred_username: "test2", keys: "yolo"}

  describe "Resolver: Get an user" do
    test "find_user/3 returns an user by its id", %{conn: conn} do
      user = insert(:user)
      modo = insert(:user, role: :moderator)

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(
          query: @get_user_query,
          variables: %{id: user.id}
        )

      assert res["data"]["user"]["email"] == user.email

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(
          query: @get_user_query,
          variables: %{id: 0}
        )

      assert res["data"]["user"] == nil
      assert hd(res["errors"])["message"] == "User with ID #{0} not found"
    end

    test "get_current_user/3 returns the current logged-in user", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @logged_user_query,
          variables: %{}
        )

      assert res["data"]["loggedUser"] == nil

      assert hd(res["errors"])["message"] ==
               "You need to be logged in"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @logged_user_query,
          variables: %{}
        )

      assert res["data"]["loggedUser"]["id"] == to_string(user.id)
    end
  end

  describe "Resolver: List users" do
    test "list_users/3 doesn't return anything with a non moderator user", %{conn: conn} do
      insert(:user, email: "riri@example.com", role: :moderator)
      user = insert(:user, email: "fifi@example.com")
      insert(:user, email: "loulou@example.com", role: :administrator)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{}
        )

      assert hd(res["errors"])["message"] ==
               "You don't have permission to do this"
    end

    test "list_users/3 returns a list of users", %{conn: conn} do
      user = insert(:user, email: "riri@example.com", role: :moderator)
      insert(:user, email: "fifi@example.com")
      insert(:user, email: "loulou@example.com")

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{}
        )

      assert res["errors"] == nil
      assert res["data"]["users"]["total"] == 3
      assert res["data"]["users"]["elements"] |> length == 3

      assert res["data"]["users"]["elements"]
             |> Enum.map(& &1["email"]) == [
               "loulou@example.com",
               "fifi@example.com",
               "riri@example.com"
             ]

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{page: 2, limit: 1}
        )

      assert res["errors"] == nil
      assert res["data"]["users"]["total"] == 3
      assert res["data"]["users"]["elements"] |> length == 1

      assert res["data"]["users"]["elements"] |> Enum.map(& &1["email"]) == [
               "fifi@example.com"
             ]

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @list_users_query,
          variables: %{page: 3, limit: 1, sort: "ID", direction: "DESC"}
        )

      assert res["errors"] == nil
      assert res["data"]["users"]["total"] == 3
      assert res["data"]["users"]["elements"] |> length == 1

      assert res["data"]["users"]["elements"] |> Enum.map(& &1["email"]) == [
               "riri@example.com"
             ]
    end
  end

  describe "Resolver: Create an user & actor" do
    @user_creation %{
      email: "test@demo.tld",
      password: "long password",
      locale: "fr_FR",
      preferredUsername: "toto",
      name: "Sir Toto",
      summary: "Sir Toto, prince of the functional tests"
    }
    @user_creation_bad_email %{
      email: "y@l@",
      password: "long password"
    }

    test "test create_user/3 creates an user and register_person/3 registers a profile",
         %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      assert res["data"]["createUser"]["email"] == @user_creation.email
      assert res["data"]["createUser"]["locale"] == @user_creation.locale

      {:ok, user} = Users.get_user_by_email(@user_creation.email)

      assert_delivered_email(Email.User.confirmation_email(user, @user_creation.locale))

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @register_person_mutation,
          variables: @user_creation
        )

      assert res["data"]["registerPerson"]["preferredUsername"] ==
               @user_creation.preferredUsername
    end

    test "create_user/3 doesn't allow two users with the same email", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      assert res["data"]["createUser"]["email"] == @user_creation.email

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      assert hd(res["errors"])["message"] == ["Cette adresse e-mail est déjà utilisée."]
    end

    test "create_user/3 doesn't allow registration when registration is closed", %{conn: conn} do
      Config.put([:instance, :registrations_open], false)
      Config.put([:instance, :registration_email_allowlist], [])

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      assert hd(res["errors"])["message"] == "Registrations are not open"
      Config.put([:instance, :registrations_open], true)
    end

    test "create_user/3 doesn't allow registration when user email is not on the allowlist", %{
      conn: conn
    } do
      Config.put([:instance, :registrations_open], false)
      Config.put([:instance, :registration_email_allowlist], ["random.org"])

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      assert hd(res["errors"])["message"] == "Your email is not on the allowlist"
      Config.put([:instance, :registrations_open], true)
      Config.put([:instance, :registration_email_allowlist], [])
    end

    test "create_user/3 allows registration when user email domain is on the allowlist", %{
      conn: conn
    } do
      Config.put([:instance, :registrations_open], false)
      Config.put([:instance, :registration_email_allowlist], ["demo.tld"])

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      refute res["errors"]
      assert res["data"]["createUser"]["email"] == @user_creation.email
      Config.put([:instance, :registrations_open], true)
      Config.put([:instance, :registration_email_allowlist], [])
    end

    test "create_user/3 allows registration when user email is on the allowlist", %{conn: conn} do
      Config.put([:instance, :registrations_open], false)
      Config.put([:instance, :registration_email_allowlist], [@user_creation.email])

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation
        )

      refute res["errors"]
      assert res["data"]["createUser"]["email"] == @user_creation.email
      Config.put([:instance, :registrations_open], true)
      Config.put([:instance, :registration_email_allowlist], [])
    end

    test "register_person/3 doesn't register a profile from an unknown email", %{conn: conn} do
      conn
      |> AbsintheHelpers.graphql_query(
        query: @create_user_mutation,
        variables: @user_creation
      )

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @register_person_mutation,
          variables: Map.put(@user_creation, :email, "random")
        )

      assert hd(res["errors"])["message"] ==
               "Aucun·e utilisateur·ice avec cette adresse e-mail n'a été trouvé·e"
    end

    test "register_person/3 can't be called with an existing profile", %{conn: conn} do
      conn
      |> AbsintheHelpers.graphql_query(
        query: @create_user_mutation,
        variables: @user_creation
      )

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @register_person_mutation,
          variables: @user_creation
        )

      assert res["data"]["registerPerson"]["preferredUsername"] ==
               @user_creation.preferredUsername

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @register_person_mutation,
          variables: @user_creation
        )

      assert hd(res["errors"])["message"] ==
               "Vous avez déjà un profil pour cet utilisateur"
    end

    test "register_person/3 is case insensitive", %{conn: conn} do
      insert(:actor, preferred_username: "myactor")

      conn
      |> AbsintheHelpers.graphql_query(
        query: @create_user_mutation,
        variables: @user_creation
      )

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @register_person_mutation,
          variables: Map.put(@user_creation, :preferredUsername, "Myactor")
        )

      refute is_nil(res["errors"])

      assert hd(res["errors"])["message"] ==
               ["Cet identifiant est déjà pris."]
    end

    test "test create_user/3 doesn't create an user with bad email", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_user_mutation,
          variables: @user_creation_bad_email
        )

      assert hd(res["errors"])["message"] ==
               ["Email doesn't fit required format"]
    end
  end

  describe "Resolver: Validate an user" do
    test "test validate_user/3 validates an user", context do
      {:ok, %User{} = user} = Users.register(@valid_actor_params)

      mutation = """
          mutation {
            validateUser(
                  token: "#{user.confirmation_token}"
              ) {
                accessToken,
                user {
                  id,
                },
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["validateUser"]["user"]["id"] == to_string(user.id)
    end

    test "test validate_user/3 with invalid token doesn't validate an user", context do
      insert(:user, confirmation_token: "t0t0")

      mutation = """
          mutation {
            validateUser(
                  token: "no pass"
              ) {
                accessToken,
                user {
                  id
                },
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "Unable to validate user"
    end
  end

  describe "Resolver: Resend confirmation emails" do
    test "test resend_confirmation_email/3 with valid email resends an validation email",
         context do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      mutation = """
          mutation {
            resendConfirmationEmail(
                  email: "#{user.email}"
              )
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You requested again a confirmation email too soon"

      # Hammer time !
      Users.update_user(user, %{
        confirmation_sent_at: Timex.shift(user.confirmation_sent_at, hours: -3)
      })

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["resendConfirmationEmail"] == user.email
      assert_delivered_email(Email.User.confirmation_email(user))
    end

    test "test resend_confirmation_email/3 with invalid email resends an validation email",
         context do
      mutation = """
          mutation {
            resendConfirmationEmail(
                  email: "oh no"
              )
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "No user to validate with this email was found"
    end
  end

  describe "Resolver: Send reset password" do
    test "test send_reset_password/3 with valid email", %{conn: conn} do
      %User{email: email} = insert(:user)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @send_reset_password_mutation,
          variables: %{email: email}
        )

      assert res["data"]["sendResetPassword"] == email
    end

    test "test send_reset_password/3 with invalid email", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @send_reset_password_mutation,
          variables: %{email: "not an email"}
        )

      assert hd(res["errors"])["message"] ==
               "No user with this email was found"
    end

    test "test send_reset_password/3 for an LDAP user", %{conn: conn} do
      {:ok, %User{email: email}} = Users.create_external("some@users.com", "ldap")

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @send_reset_password_mutation,
          variables: %{email: email}
        )

      assert hd(res["errors"])["message"] ==
               "This user can't reset their password"
    end

    test "test send_reset_password/3 for a deactivated user doesn't send email", %{conn: conn} do
      {:ok, %User{email: email} = user} =
        Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      Users.update_user(user, %{confirmed_at: DateTime.utc_now(), disabled: true})

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @send_reset_password_mutation,
          variables: %{email: email}
        )

      assert hd(res["errors"])["message"] ==
               "No user with this email was found"
    end
  end

  describe "Resolver: Reset user's password" do
    test "test reset_password/3 with valid email", context do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})
      Users.update_user(user, %{confirmed_at: DateTime.utc_now()})
      %Actor{} = insert(:actor, user: user)
      {:ok, _email_sent} = Email.User.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Users.get_user!(user.id)

      mutation = """
          mutation {
            resetPassword(
                  token: "#{reset_password_token}",
                  password: "new password"
              ) {
                user {
                  id
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert is_nil(json_response(res, 200)["errors"])
      assert json_response(res, 200)["data"]["resetPassword"]["user"]["id"] == to_string(user.id)
    end

    test "test reset_password/3 with a password too short", context do
      %User{} = user = insert(:user)
      {:ok, _email_sent} = Email.User.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Users.get_user!(user.id)

      mutation = """
          mutation {
            resetPassword(
                  token: "#{reset_password_token}",
                  password: "new"
              ) {
                user {
                  id
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "The password you have choosen is too short. Please make sure your password contains at least 6 charaters."
    end

    test "test reset_password/3 with an invalid token", context do
      %User{} = user = insert(:user)
      {:ok, _email_sent} = Email.User.send_password_reset_email(user)
      %User{} = Users.get_user!(user.id)

      mutation = """
          mutation {
            resetPassword(
                  token: "not good",
                  password: "new"
              ) {
                user {
                  id
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "The token you provided is invalid. Make sure that the URL is exactly the one provided inside the email you got."
    end
  end

  describe "Resolver: Login a user" do
    test "test login_user/3 with valid credentials", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: user.email, password: user.password}
        )

      assert login = res["data"]["login"]
      assert Map.has_key?(login, "accessToken") && not is_nil(login["accessToken"])
    end

    test "test login_user/3 with invalid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: user.email, password: "bad password"}
        )

      assert hd(res["errors"])["message"] ==
               "Impossible to authenticate, either your email or password are invalid."
    end

    test "test login_user/3 with invalid email", %{conn: conn} do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: "bad email", password: "bad password"}
        )

      assert hd(res["errors"])["message"] ==
               "User not found"
    end

    test "test login_user/3 with unconfirmed user", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: user.email, password: user.password}
        )

      assert hd(res["errors"])["message"] == "User not found"
    end
  end

  describe "Resolver: Refresh a token" do
    test "test refresh_token/3 with a bad token", context do
      mutation = """
          mutation {
            refreshToken(
              refreshToken: "bad_token"
            ) {
              accessToken
            }
          }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Cannot refresh the token"
    end

    test "test refresh_token/3 with an appropriate token", context do
      user = insert(:user)
      {:ok, refresh_token} = Authenticator.generate_refresh_token(user)

      mutation = """
          mutation {
            refreshToken(
              refreshToken: "#{refresh_token}"
            ) {
              accessToken
            }
          }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      access_token = json_response(res, 200)["data"]["refreshToken"]["accessToken"]
      assert String.length(access_token) > 10

      query = """
      {
          loggedPerson {
            preferredUsername,
          }
        }
      """

      res =
        context.conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{access_token}")
        |> post("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["errors"] == nil
    end
  end

  describe "Resolver: change default actor for user" do
    test "test change_default_actor/3 without being logged-in", %{conn: conn} do
      # Prepare user with two actors
      user = insert(:user)
      insert(:actor, user: user)

      assert {:ok, %User{actors: _actors}} = Users.get_user_with_actors(user.id)

      actor_params = @valid_single_actor_params |> Map.put(:user_id, user.id)
      assert {:ok, %Actor{} = actor2} = Actors.create_actor(actor_params)

      assert {:ok, %User{actors: actors}} = Users.get_user_with_actors(user.id)
      assert length(actors) == 2

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @change_default_actor,
          variables: %{preferredUsername: actor2.preferred_username}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "test change_default_actor/3 with valid actor", %{conn: conn} do
      # Prepare user with two actors
      user = insert(:user)
      insert(:actor, user: user)

      assert {:ok, %User{actors: _actors}} = Users.get_user_with_actors(user.id)

      actor_params = @valid_single_actor_params |> Map.put(:user_id, user.id)
      assert {:ok, %Actor{} = actor2} = Actors.create_actor(actor_params)

      assert {:ok, %User{actors: actors}} = Users.get_user_with_actors(user.id)
      assert length(actors) == 2

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_default_actor,
          variables: %{preferredUsername: actor2.preferred_username}
        )

      assert res["errors"] == nil

      assert res["data"]["changeDefaultActor"]["defaultActor"]["preferredUsername"] ==
               actor2.preferred_username
    end
  end

  describe "Resolver: Change password for an user" do
    @email "toto@tata.tld"
    @old_password "p4ssw0rd"
    @new_password "upd4t3d"

    test "change_password/3 with valid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @old_password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            login(
                  email: "#{@email}",
                  password: "#{@old_password}",
              ) {
                accessToken,
                refreshToken,
                user {
                  id
                }
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert login = json_response(res, 200)["data"]["login"]
      assert Map.has_key?(login, "accessToken") && not is_nil(login["accessToken"])

      mutation = """
          mutation {
            changePassword(old_password: "#{@old_password}", new_password: "#{@new_password}") {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["changePassword"]["id"] == to_string(user.id)

      mutation = """
          mutation {
            login(
                  email: "#{@email}",
                  password: "#{@new_password}",
              ) {
                accessToken,
                refreshToken,
                user {
                  id
                }
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert login = json_response(res, 200)["data"]["login"]
      assert Map.has_key?(login, "accessToken") && not is_nil(login["accessToken"])
    end

    test "change_password/3 with invalid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @old_password})

      # Hammer time !

      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            changePassword(old_password: "invalid password", new_password: "#{@new_password}") {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "The current password is invalid"
    end

    test "change_password/3 with same password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @old_password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            changePassword(old_password: "#{@old_password}", new_password: "#{@old_password}") {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "The new password must be different"
    end

    test "change_password/3 with new password too short", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @old_password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            changePassword(old_password: "#{@old_password}", new_password: "new") {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "The password you have chosen is too short. Please make sure your password contains at least 6 characters."
    end

    test "change_password/3 without being authenticated", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @old_password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            changePassword(old_password: "#{@old_password}", new_password: "#{@new_password}") {
                id
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to change your password"
    end
  end

  describe "Resolver: Change email for an user" do
    @old_email "old@domain.tld"
    @new_email "new@domain.tld"
    @password "p4ssw0rd"

    test "change_email/3 with valid email", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: @old_email, password: @password}
        )

      login = res["data"]["login"]
      assert Map.has_key?(login, "accessToken") && not is_nil(login["accessToken"])

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: @new_email, password: @password}
        )

      assert res["errors"] == nil
      assert res["data"]["changeEmail"]["id"] == to_string(user.id)

      user = Users.get_user!(user.id)
      assert user.email == @old_email
      assert user.unconfirmed_email == @new_email

      assert_delivered_email(Email.User.send_email_reset_old_email(user))
      assert_delivered_email(Email.User.send_email_reset_new_email(user))

      conn
      |> AbsintheHelpers.graphql_query(
        query: @validate_email_mutation,
        variables: %{token: user.confirmation_token}
      )

      user = Users.get_user!(user.id)
      assert user.email == @new_email
      assert user.unconfirmed_email == nil
    end

    test "change_email/3 with valid email but invalid token", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @login_mutation,
          variables: %{email: @old_email, password: @password}
        )

      login = res["data"]["login"]
      assert Map.has_key?(login, "accessToken") && not is_nil(login["accessToken"])

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: @new_email, password: @password}
        )

      assert res["errors"] == nil
      assert res["data"]["changeEmail"]["id"] == to_string(user.id)

      user = Users.get_user!(user.id)
      assert user.email == @old_email
      assert user.unconfirmed_email == @new_email

      assert_delivered_email(Email.User.send_email_reset_old_email(user))
      assert_delivered_email(Email.User.send_email_reset_new_email(user))

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @validate_email_mutation,
          variables: %{token: "some token"}
        )

      assert hd(res["errors"])["message"] == "Invalid activation token"

      user = Users.get_user!(user.id)
      assert user.email == @old_email
      assert user.unconfirmed_email == @new_email
    end

    test "change_email/3 with invalid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: @new_email, password: "invalid_password"}
        )

      assert hd(res["errors"])["message"] == "The password provided is invalid"
    end

    test "change_email/3 with same email", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: @old_email, password: @password}
        )

      assert hd(res["errors"])["message"] == "The new email must be different"
    end

    test "change_email/3 with invalid email", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: "invalid email", password: @password}
        )

      assert hd(res["errors"])["message"] == "The new email doesn't seem to be valid"
    end

    test "change_password/3 without being authenticated", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @old_email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @change_email_mutation,
          variables: %{email: @new_email, password: @password}
        )

      assert hd(res["errors"])["message"] ==
               "You need to be logged-in to change your email"
    end
  end

  describe "Resolver: User deletes it's account" do
    @email "mail@domain.tld"
    @password "p4ssw0rd"

    test "delete_account/3 with valid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      # Hammer time !
      {:ok, %User{} = user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      %Actor{} = actor1 = insert(:actor, user: user)
      %Actor{} = actor2 = insert(:actor, user: user)
      %Event{id: event_id} = event = insert(:event, organizer_actor: actor1)

      %Participant{id: participant_id} =
        insert(:participant, event: event, actor: actor2, role: :participant)

      %Comment{id: comment_id} = insert(:comment, actor: actor2, event: event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_user_account_mutation,
          variables: %{password: @password}
        )

      assert res["data"]["deleteAccount"]["id"] == to_string(user.id)

      assert [
               %Oban.Job{args: %{"actor_id" => actor2_id, "op" => "delete_actor"}},
               %Oban.Job{args: %{"actor_id" => actor1_id, "op" => "delete_actor"}}
             ] = all_enqueued(queue: :background)

      assert MapSet.new([actor1.id, actor2.id]) == MapSet.new([actor1_id, actor2_id])

      assert is_nil(Users.get_user(user.id))

      assert %{success: 2, failure: 0} == Oban.drain_queue(queue: :background)

      assert_raise Ecto.NoResultsError, fn ->
        Events.get_event!(event_id)
      end

      assert_raise Ecto.NoResultsError, fn ->
        Discussions.get_comment!(comment_id)
      end

      # Actors are not deleted but emptied (to keep the  username reserved)
      actor1 = Actors.get_actor!(actor1_id)
      assert actor1.suspended
      assert is_nil(actor1.name)

      actor2 = Actors.get_actor!(actor2_id)
      assert actor2.suspended
      assert is_nil(actor2.name)

      assert is_nil(Events.get_participant(participant_id))
    end

    test "delete_account/3 with 3rd-party auth login", %{conn: conn} do
      {:ok, %User{} = user} = Users.create_external(@email, "keycloak")

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @delete_user_account_mutation)

      assert is_nil(res["errors"])
      assert res["data"]["deleteAccount"]["id"] == to_string(user.id)
    end

    test "delete_account/3 with invalid password", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      # Hammer time !
      {:ok, %User{} = user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_user_account_mutation,
          variables: %{password: "invalid password"}
        )

      assert hd(res["errors"])["message"] == "The password provided is invalid"
    end

    test "delete_account/3 without being authenticated", %{conn: conn} do
      {:ok, %User{} = user} = Users.register(%{email: @email, password: @password})

      # Hammer time !
      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          confirmed_at: Timex.shift(user.confirmation_sent_at, hours: -3),
          confirmation_sent_at: nil,
          confirmation_token: nil
        })

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @delete_user_account_mutation,
          variables: %{password: "invalid password"}
        )

      assert hd(res["errors"])["message"] ==
               "You need to be logged-in to delete your account"
    end
  end
end
