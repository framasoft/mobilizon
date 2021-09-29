defmodule Mobilizon.GraphQL.Resolvers.Users.ActivitySettings do
  @moduledoc """
  Handles the user activity settings-related GraphQL calls.
  """

  alias Mobilizon.Users
  alias Mobilizon.Users.{ActivitySetting, User}

  require Logger

  @spec user_activity_settings(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, list(ActivitySetting.t())} | {:error, :unauthenticated}
  def user_activity_settings(_parent, _args, %{context: %{current_user: %User{} = user}}) do
    {:ok, Users.activity_settings_for_user(user)}
  end

  def user_activity_settings(_parent, _args, _context) do
    {:error, :unauthenticated}
  end

  @spec upsert_user_activity_setting(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, ActivitySetting.t()} | {:error, :unauthenticated}
  def upsert_user_activity_setting(_parent, args, %{context: %{current_user: %User{id: user_id}}}) do
    Users.create_activity_setting(Map.put(args, :user_id, user_id))
  end

  def upsert_user_activity_setting(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end
end
