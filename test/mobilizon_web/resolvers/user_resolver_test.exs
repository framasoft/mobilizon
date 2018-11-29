defmodule MobilizonWeb.Resolvers.UserResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{User, Actor}
  alias MobilizonWeb.AbsintheHelpers
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

  describe "Resolver: Create an user & actor" do
    @account_creation %{
      email: "test@demo.tld",
      password: "long password",
      username: "test_account"
    }
    @account_creation_bad_email %{
      email: "y@l@",
      password: "long password",
      username: "test_account"
    }

    test "test create_user_actor/3 creates an user", context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@account_creation.email}",
                  password: "#{@account_creation.password}",
                  username: "#{@account_creation.username}"
              ) {
                default_actor {
                  preferred_username,
                },
                email
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createUser"]["default_actor"]["preferred_username"] ==
               @account_creation.username

      assert json_response(res, 200)["data"]["createUser"]["email"] == @account_creation.email
    end

    test "test create_user_actor/3 doesn't create an user with bad email", context do
      mutation = """
          mutation {
            createUser(
                  email: "#{@account_creation_bad_email.email}",
                  password: "#{@account_creation.password}",
                  username: "#{@account_creation.username}"
              ) {
                default_actor {
                  preferred_username,
                },
                email,
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
    @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
    test "test validate_user/3 validates an user", context do
      {:ok, %User{default_actor: %Actor{} = _actor} = user} = Actors.register(@valid_actor_params)

      mutation = """
          mutation {
            validateUser(
                  token: "#{user.confirmation_token}"
              ) {
                token,
                user {
                  id,
                  default_actor {
                    preferredUsername
                  }
                },
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["validateUser"]["user"]["default_actor"][
               "preferredUsername"
             ] == @valid_actor_params.username

      assert json_response(res, 200)["data"]["validateUser"]["user"]["id"] == to_string(user.id)
    end

    test "test validate_user/3 with invalid token doesn't validate an user", context do
      {:ok, %User{default_actor: %Actor{} = _actor} = _user} =
        Actors.register(@valid_actor_params)

      mutation = """
          mutation {
            validateUser(
                  token: "no pass"
              ) {
                token,
                user {
                  id,
                  default_actor {
                    preferredUsername
                  }
                },
              }
            }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "validation_failed"
    end
  end

  describe "Resolver: Resend confirmation emails" do
    test "test resend_confirmation_email/3 with valid email resends an validation email",
         context do
      {:ok, %User{default_actor: %Actor{} = _actor} = user} = Actors.register(@valid_actor_params)

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
      Mobilizon.Actors.update_user(user, %{
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
      {:ok, %User{default_actor: %Actor{} = _actor} = _user} =
        Actors.register(@valid_actor_params)

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
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)
      {:ok, _email_sent} = Mobilizon.Actors.Service.ResetPassword.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Mobilizon.Actors.get_user!(user.id)

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
      {:ok, _email_sent} = Mobilizon.Actors.Service.ResetPassword.send_password_reset_email(user)
      %User{reset_password_token: reset_password_token} = Mobilizon.Actors.get_user!(user.id)

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

      assert hd(json_response(res, 200)["errors"])["message"] == "password_too_short"
    end

    test "test reset_password/3 with an invalid token", context do
      %User{} = user = insert(:user)
      {:ok, _email_sent} = Mobilizon.Actors.Service.ResetPassword.send_password_reset_email(user)
      %User{} = Mobilizon.Actors.get_user!(user.id)

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

      assert hd(json_response(res, 200)["errors"])["message"] == "invalid_token"
    end
  end

  describe "Resolver: Login an user" do
    test "test login_user/3 with valid credentials", context do
      {:ok, %User{} = user} = Actors.register(@valid_actor_params)

      {:ok, %User{} = _user} =
        Actors.update_user(user, %{
          "confirmed_at" => DateTime.utc_now(),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            login(
                  email: "#{@valid_actor_params.email}",
                  password: "#{@valid_actor_params.password}",
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

      assert login = json_response(res, 200)["data"]["login"]
      assert Map.has_key?(login, "token") && not is_nil(login["token"])
      assert login["user"]["default_actor"]["preferred_username"] == @valid_actor_params.username
    end

    test "test login_user/3 with invalid password", context do
      {:ok, %User{} = user} = Actors.register(@valid_actor_params)

      {:ok, %User{} = _user} =
        Actors.update_user(user, %{
          "confirmed_at" => DateTime.utc_now(),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

      mutation = """
          mutation {
            login(
                  email: "#{@valid_actor_params.email}",
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

      assert hd(json_response(res, 200)["errors"])["message"] == "Impossible to authenticate"
    end

    test "test login_user/3 with invalid email", context do
      {:ok, %User{} = user} = Actors.register(@valid_actor_params)

      {:ok, %User{} = _user} =
        Actors.update_user(user, %{
          "confirmed_at" => DateTime.utc_now(),
          "confirmation_sent_at" => nil,
          "confirmation_token" => nil
        })

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
      assert {:ok, %User{id: user_id, default_actor: %Actor{} = actor} = user} =
               Actors.register(@valid_actor_params)

      assert {:ok, %User{actors: actors}} = Actors.get_user_with_actors(user_id)

      actor_params = @valid_single_actor_params |> Map.put(:user_id, user_id)
      assert {:ok, %Actor{} = actor2} = Actors.create_actor(actor_params)

      assert {:ok, %User{actors: actors}} = Actors.get_user_with_actors(user_id)
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
