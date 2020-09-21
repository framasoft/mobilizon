defmodule Mobilizon.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox, as: Adapter

  alias Mobilizon.Config
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Uploader

  using do
    quote do
      alias Mobilizon.Storage.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Mobilizon.DataCase
    end
  end

  setup tags do
    :ok = Adapter.checkout(Repo)

    unless tags[:async], do: Adapter.mode(Repo, {:shared, self()})

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Actors.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def ensure_local_uploader(_context) do
    uploader = Config.get([Upload, :uploader])
    filters = Config.get([Upload, :filters])

    unless uploader == Uploader.Local || filters != [] do
      Config.put([Upload, :uploader], Uploader.Local)
      Config.put([Upload, :filters], [])

      on_exit(fn ->
        Config.put([Upload, :uploader], uploader)
        Config.put([Upload, :filters], filters)
      end)
    end

    :ok
  end

  Mox.defmock(Mobilizon.Service.HTTP.ActivityPub.Mock, for: Tesla.Adapter)
  Mox.defmock(Mobilizon.Service.HTTP.GeospatialClient.Mock, for: Tesla.Adapter)
end
