defmodule MobilizonWeb.Resolvers.UserResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  alias MobilizonWeb.AbsintheHelpers
  alias Mobilizon.Service.Users.ResetPassword
  import Mobilizon.Factory
  use Bamboo.Test

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
  @valid_single_actor_params %{preferred_username: "test2", keys: "yolo"}

  describe "Resolver: Get an user" do
    test "find_user/3 returns an user by it's id", context do
      user = insert(:user)

      query = """
      {
        user(id: "#{user.id}") {
            email,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert json_response(res, 200)["data"]["user"]["email"] == user.email

      query = """
      {
        user(id: "#{0}") {
          email,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert json_response(res, 200)["data"]["user"] == nil
      assert hd(json_response(res, 200)["errors"])["message"] == "User with ID #{0} not found"
    end

    test "get_current_user/3 returns the current logged-in user", context do
      user = insert(:user)

      query = """
      {
          loggedUser {
            id
          }
        }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_user"))

      assert json_response(res, 200)["data"]["loggedUser"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to view current user"

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_user"))

      assert json_response(res, 200)["data"]["loggedUser"]["id"] == to_string(user.id)
    end
  end

  describe "Resolver: List users" do
    test "list_users/3 doesn't return anything with a non moderator user", context do
      insert(:user, email: "riri@example.com", role: :moderator)
      user = insert(:user, email: "fifi@example.com")
      insert(:user, email: "loulou@example.com", role: :administrator)

      query = """
      {
        users {
          total,
          elements {
            email
          }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to have admin access to list users"
    end

    test "list_users/3 returns a list of users", context do
      user = insert(:user, email: "riri@example.com", role: :moderator)
      insert(:user, email: "fifi@example.com")
      insert(:user, email: "loulou@example.com")

      query = """
      {
        users {
          total,
          elements {
            email
          }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["users"]["total"] == 3
      assert json_response(res, 200)["data"]["users"]["elements"] |> length == 3

      assert json_response(res, 200)["data"]["users"]["elements"]
             |> Enum.map(& &1["email"]) == [
               "loulou@example.com",
               "fifi@example.com",
               "riri@example.com"
             ]

      query = """
      {
        users(page: 2, limit: 1) {
          total,
          elements {
            email
          }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["users"]["total"] == 3
      assert json_response(res, 200)["data"]["users"]["elements"] |> length == 1

      assert json_response(res, 200)["data"]["users"]["elements"] |> Enum.map(& &1["email"]) == [
               "fifi@example.com"
             ]

      query = """
      {
        users(page: 3, limit: 1, sort: ID, direction: DESC) {
          total,
          elements {
            email
          }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "user"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["users"]["total"] == 3
      assert json_response(res, 200)["data"]["users"]["elements"] |> length == 1

      assert json_response(res, 200)["data"]["users"]["elements"] |> Enum.map(& &1["email"]) == [
               "riri@example.com"
             ]
    end

    test "get_current_user/3 returns the current logged-in user", context do
      user = insert(:user)

      query = """
      {
          loggedUser {
            id
          }
        }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_user"))

      assert json_response(res, 200)["data"]["loggedUser"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to view current user"

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_user"))

      assert json_response(res, 200)["data"]["loggedUser"]["id"] == to_string(user.id)
    end
  end

  describe "Resolver: Create an user & actor" do
    @user_creation %{
      email: "test@demo.tld",
      password: "long password",
      username: "toto",
      name: "Sir Toto",
      summary: "Sir Toto, prince of the functional tests"
    }
    @user_creation_bad_email %{
      email: "y@l@",
      password: "long password"
    }

    test "test create_user/3 creates an user and register_person/3 registers a profile",
         context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@user_creation.email}",
                  password: "#{@user_creation.password}",
              ) {
                id,
                email
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createUser"]["email"] == @user_creation.email

      mutation = """
          mutation {
            registerPerson(
              preferredUsername: "#{@user_creation.username}",
              name: "#{@user_creation.name}",
              summary: "#{@user_creation.summary}",
              email: "#{@user_creation.email}",
              ) {
                preferredUsername,
                name,
                summary,
                avatarUrl,
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["registerPerson"]["preferredUsername"] ==
               @user_creation.username
    end

    test "register_person/3 doesn't register a profile from an unknown email", context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@user_creation.email}",
                  password: "#{@user_creation.password}",
              ) {
                id,
                email
              }
            }
      """

      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      mutation = """
          mutation {
            registerPerson(
              preferredUsername: "#{@user_creation.username}",
              name: "#{@user_creation.name}",
              summary: "#{@user_creation.summary}",
              email: "random",
              ) {
                preferredUsername,
                name,
                summary,
                avatarUrl,
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "User with email not found"
    end

    test "register_person/3 can't be called with an existing profile", context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@user_creation.email}",
                  password: "#{@user_creation.password}",
              ) {
                id,
                email
              }
            }
      """

      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      mutation = """
          mutation {
            registerPerson(
              preferredUsername: "#{@user_creation.username}",
              name: "#{@user_creation.name}",
              summary: "#{@user_creation.summary}",
              email: "#{@user_creation.email}",
              ) {
                preferredUsername,
                name,
                summary,
                avatarUrl,
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["registerPerson"]["preferredUsername"] ==
               @user_creation.username

      mutation = """
          mutation {
            registerPerson(
              preferredUsername: "#{@user_creation.username}",
              name: "#{@user_creation.name}",
              summary: "#{@user_creation.summary}",
              email: "#{@user_creation.email}",
              ) {
                preferredUsername,
                name,
                summary,
                avatarUrl,
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You already have a profile for this user"
    end

    test "test create_user/3 doesn't create an user with bad email", context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@user_creation_bad_email.email}",
                  password: "#{@user_creation_bad_email.password}",
              ) {
                id,
                email
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Email doesn't fit required format"
    end
  end

  describe "Resolver: Validate an user" do
    @valid_actor_params %{email: "test@test.tld", password: "testest"}
    test "test validate_user/3 validates an user", context do
      {:ok, %User{} = user} = Users.register(@valid_actor_params)

      mutation = """
          mutation {
            validateUser(
                  token: "#{user.confirmation_token}"
              ) {
                token,
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
                token,
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
      Mobilizon.Users.update_user(user, %{
        confirmation_sent_at: Timex.shift(user.confirmation_sent_at, hours: -3)
      })

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["resendConfirmationEmail"] == user.email
      assert_delivered_email(Mobilizon.Email.User.confirmation_email(user))
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
    test "test send_reset_password/3 with valid email", context do
      user = insert(:user)

      mutation = """
          mutation {
            sendResetPassword(
                  email: "#{user.email}"
              )
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["sendResetPassword"] == user.email
    end

    test "test send_reset_password/3 with invalid email", context do
      mutation = """
          mutation {
            sendResetPassword(
                  email: "oh no"
              )
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "No user with this email was found"
    end
  end

  describe "Resolver: Reset user's password" do
    test "test reset_password/3 with valid email", context do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})
      %Actor{} = insert(:actor, user: user)
      {:ok, _email_sent} = ResetPassword.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Mobilizon.Users.get_user!(user.id)

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

      assert json_response(res, 200)["data"]["resetPassword"]["user"]["id"] == to_string(user.id)
    end

    test "test reset_password/3 with a password too short", context do
      %User{} = user = insert(:user)
      {:ok, _email_sent} = ResetPassword.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Mobilizon.Users.get_user!(user.id)

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
      {:ok, _email_sent} = ResetPassword.send_password_reset_email(user)
      %User{} = Mobilizon.Users.get_user!(user.id)

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

  describe "Resolver: Login an user" do
    test "test login_user/3 with valid credentials", context do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            login(
                  email: "#{user.email}",
                  password: "#{user.password}",
              ) {
                token,
                user {
                  id
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert login = json_response(res, 200)["data"]["login"]
      assert Map.has_key?(login, "token") && not is_nil(login["token"])
    end

    test "test login_user/3 with invalid password", context do
      {:ok, %User{} = user} = Users.register(%{email: "toto@tata.tld", password: "p4ssw0rd"})

      {:ok, %User{} = _user} =
        Users.update_user(user, %{
          "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            login(
                  email: "#{user.email}",
                  password: "bad password",
              ) {
                token,
                user {
                  default_actor {
                    preferred_username,
                  }
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Impossible to authenticate, either your email or password are invalid."
    end

    test "test login_user/3 with invalid email", context do
      mutation = """
          mutation {
            login(
                  email: "bad email",
                  password: "bad password",
              ) {
                token,
                user {
                  default_actor {
                    preferred_username,
                  }
                }
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "User with email not found"
    end
  end

  describe "Resolver: change default actor for user" do
    test "test change_default_actor/3 with valid actor", context do
      # Prepare user with two actors
      user = insert(:user)
      insert(:actor, user: user)

      assert {:ok, %User{actors: actors}} = Users.get_user_with_actors(user.id)

      actor_params = @valid_single_actor_params |> Map.put(:user_id, user.id)
      assert {:ok, %Actor{} = actor2} = Actors.create_actor(actor_params)

      assert {:ok, %User{actors: actors}} = Users.get_user_with_actors(user.id)
      assert length(actors) == 2

      mutation = """
          mutation {
            changeDefaultActor(preferred_username: "#{actor2.preferred_username}") {
                default_actor {
                  preferred_username
                }
              }
            }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["changeDefaultActor"]["default_actor"][
               "preferred_username"
             ] == actor2.preferred_username
    end
  end
end
