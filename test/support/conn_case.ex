defmodule MobilizonWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox, as: Adapter

  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import MobilizonWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint MobilizonWeb.Endpoint

      def auth_conn(%Plug.Conn{} = conn, %User{} = user) do
        {:ok, token, _claims} = MobilizonWeb.Auth.Guardian.encode_and_sign(user)

        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Plug.Conn.put_req_header("accept", "application/json")
      end
    end
  end

  setup tags do
    :ok = Adapter.checkout(Repo)

    unless tags[:async], do: Adapter.mode(Repo, {:shared, self()})

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
