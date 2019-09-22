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

  alias Mobilizon.Config

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
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Mobilizon.Storage.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Mobilizon.Storage.Repo, {:shared, self()})
    end

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
    uploader = Config.get([MobilizonWeb.Upload, :uploader])
    filters = Config.get([MobilizonWeb.Upload, :filters])

    unless uploader == MobilizonWeb.Uploaders.Local || filters != [] do
      Config.put([MobilizonWeb.Upload, :uploader], MobilizonWeb.Uploaders.Local)
      Config.put([MobilizonWeb.Upload, :filters], [])

      on_exit(fn ->
        Config.put([MobilizonWeb.Upload, :uploader], uploader)
        Config.put([MobilizonWeb.Upload, :filters], filters)
      end)
    end

    :ok
  end
end
