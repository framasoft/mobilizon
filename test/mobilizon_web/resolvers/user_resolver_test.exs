defmodule MobilizonWeb.Resolvers.UserResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{User, Actor}
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory
  use Bamboo.Test

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}

  describe "User Resolver" do
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

  @account_creation %{email: "test@demo.tld", password: "long password", username: "test_account"}
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
              preferred_username,
              user {
                email
              }
            }
          }
    """

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert json_response(res, 200)["data"]["createUser"]["preferred_username"] ==
             @account_creation.username

    assert json_response(res, 200)["data"]["createUser"]["user"]["email"] ==
             @account_creation.email
  end

  test "test create_user_actor/3 doesn't create an user with bad email", context do
    mutation = """
        mutation {
          createUser(
                email: "#{@account_creation_bad_email.email}",
                password: "#{@account_creation.password}",
                username: "#{@account_creation.username}"
            ) {
              preferred_username,
              user {
                email
              }
            }
          }
    """

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert hd(json_response(res, 200)["errors"])["message"] == "Email doesn't fit required format"
  end

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
  test "test validate_user/3 validates an user", context do
    {:ok, actor} = Actors.register(@valid_actor_params)

    mutation = """
        mutation {
          validateUser(
                token: "#{actor.user.confirmation_token}"
            ) {
              token,
              user {
                id
              },
              person {
                preferredUsername
              }
            }
          }
    """

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert json_response(res, 200)["data"]["validateUser"]["person"]["preferredUsername"] ==
             @valid_actor_params.username

    assert json_response(res, 200)["data"]["validateUser"]["user"]["id"] ==
             to_string(actor.user.id)
  end

  test "test validate_user/3 with invalid token doesn't validate an user", context do
    {:ok, _actor} = Actors.register(@valid_actor_params)

    mutation = """
        mutation {
          validateUser(
                token: "no pass"
            ) {
              token,
              user {
                id
              },
              person {
                preferredUsername
              }
            }
          }
    """

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert hd(json_response(res, 200)["errors"])["message"] == "Invalid token"
  end

  test "test resend_confirmation_email/3 with valid email resends an validation email", context do
    {:ok, actor} = Actors.register(@valid_actor_params)

    mutation = """
        mutation {
          resendConfirmationEmail(
                email: "#{actor.user.email}"
            )
          }
    """

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert hd(json_response(res, 200)["errors"])["message"] ==
             "You requested again a confirmation email too soon"

    # Hammer time !
    Mobilizon.Actors.update_user(actor.user, %{
      confirmation_sent_at: Timex.shift(actor.user.confirmation_sent_at, hours: -3)
    })

    res =
      context.conn
      |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

    assert json_response(res, 200)["data"]["resendConfirmationEmail"] == actor.user.email
    assert_delivered_email(Mobilizon.Email.User.confirmation_email(actor.user))
  end

  test "test resend_confirmation_email/3 with invalid email resends an validation email",
       context do
    {:ok, _actor} = Actors.register(@valid_actor_params)

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

    assert hd(json_response(res, 200)["errors"])["message"] == "No user with this email was found"
  end

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
