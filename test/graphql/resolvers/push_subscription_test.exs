defmodule Mobilizon.GraphQL.Resolvers.PushSubscriptionTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "create a new push subscription" do
    @register_push_mutation """
    mutation RegisterPush($endpoint: String!, $auth: String!, $p256dh: String!) {
      registerPush(endpoint: $endpoint, auth: $auth, p256dh: $p256dh)
    }
    """

    test "without auth", %{conn: conn} do
      res =
        AbsintheHelpers.graphql_query(conn,
          query: @register_push_mutation,
          variables: %{endpoint: "https://yolo.com/gfjgfd", auth: "gjrigf", p256dh: "gbgof"}
        )

      assert hd(res["errors"])["status_code"] == 401
      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "succeeds", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @register_push_mutation,
          variables: %{endpoint: "https://yolo.com/gfjgfd", auth: "gjrigf", p256dh: "gbgof"}
        )

      assert res["errors"] == nil
      assert res["data"]["registerPush"] == "OK"
    end

    test "fails on duplicate", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @register_push_mutation,
          variables: %{
            endpoint: "https://yolo.com/duplicate",
            auth: "duplicate",
            p256dh: "duplicate"
          }
        )

      assert res["errors"] == nil
      assert res["data"]["registerPush"] == "OK"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @register_push_mutation,
          variables: %{
            endpoint: "https://yolo.com/duplicate",
            auth: "duplicate",
            p256dh: "duplicate"
          }
        )

      assert hd(res["errors"])["message"] ==
               "The same push subscription has already been registered"

      refute res["data"]["registerPush"] == "OK"
    end
  end

  describe "unregister a push subscription" do
    @unregister_push_mutation """
    mutation UnRegisterPush($endpoint: String!) {
      unregisterPush(endpoint: $endpoint)
    }
    """

    test "without auth", %{conn: conn} do
      res =
        AbsintheHelpers.graphql_query(conn,
          query: @unregister_push_mutation,
          variables: %{endpoint: "https://yolo.com/gfjgfd"}
        )

      assert hd(res["errors"])["status_code"] == 401
      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "fails when not existing", %{conn: conn} do
      user = insert(:user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unregister_push_mutation,
          variables: %{
            endpoint: "https://yolo.com/duplicate",
            auth: "duplicate",
            p256dh: "duplicate"
          }
        )

      assert hd(res["errors"])["status_code"] == 404
      assert hd(res["errors"])["message"] == "Resource not found"
      refute res["data"]["registerPush"] == "OK"
    end

    test "fails when wrong user", %{conn: conn} do
      user = insert(:user)
      push_subscription = insert(:push_subscription)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unregister_push_mutation,
          variables: %{endpoint: push_subscription.endpoint}
        )

      assert hd(res["errors"])["status_code"] == 403
      assert hd(res["errors"])["message"] == "You don't have permission to do this"
      refute res["data"]["registerPush"] == "OK"
    end

    test "succeeds", %{conn: conn} do
      user = insert(:user)
      push_subscription = insert(:push_subscription, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @unregister_push_mutation,
          variables: %{endpoint: push_subscription.endpoint}
        )

      assert res["errors"] == nil
      assert res["data"]["unregisterPush"] == "OK"
    end
  end
end
