defmodule Mobilizon.GraphQL.Authorization.AppScope do
  @moduledoc """
  Module referencing all scopes usable in the Mobilizon API
  """

  require Logger

  @global_scope %{
    "write" => [
      # Media
      :"write:media:upload",
      :"write:media:remove",
      # Event permissions
      :"write:event:create",
      :"write:event:update",
      :"write:event:delete",
      # Comment permissions
      :"write:comment:create",
      :"write:comment:update",
      :"write:comment:delete",
      # Event participation permission
      :"write:participation",
      # User account permissions
      :"write:user:settings",
      :"write:user:setting:activity",
      :"write:user:setting:push",
      # Profile permissions
      :"write:profile:create",
      :"write:profile:update",
      :"write:profile:delete",
      :"write:profile:feed_token:create",
      :"write:feed_token:delete",
      # Membership permissions
      :"write:group_membership",
      # Group permissions
      :"write:group:create",
      :"write:group:update",
      :"write:group:delete",
      # Group discussions permissions
      :"write:group:discussion:create",
      :"write:group:discussion:update",
      :"write:group:discussion:delete",
      # Group resources permissions
      :"write:group:resources:create",
      :"write:group:resources:update",
      :"write:group:resources:delete",
      # Group members
      :"write:group:members",
      # Post permissions
      :"write:group:post:create",
      :"write:group:post:update",
      :"write:group:post:delete"
    ],
    "read" => [
      :"read:event",
      :"read:event:participants",
      :"read:event:participants:export",
      :"read:user:settings",
      # Profile permissions
      :"read:profile",
      :"read:profile:organized_events",
      :"read:profile:participations",
      :"read:profile:memberships",
      :"read:profile:follows",
      # Group details permissions
      :"read:group",
      :"read:group:events",
      :"read:group:discussions",
      :"read:group:resources",
      :"read:group:followers",
      :"read:group:todo_lists",
      :"read:group:activities"
    ]
  }

  @spec get_scopes :: list(atom())
  def get_scopes do
    @global_scope
    |> Map.values()
    |> Enum.concat()
    |> Enum.concat([:read, :write])
  end

  @spec scopes_valid?(String.t()) :: boolean()
  def scopes_valid?(scopes) do
    scopes
    |> String.split(" ")
    |> Enum.all?(&scope_valid?/1)
  end

  @spec scope_valid?(String.t() | atom()) :: boolean()
  def scope_valid?(scope) when is_binary(scope) do
    scope in Enum.map(get_scopes(), &to_string/1)
  end

  def scope_valid?(scope) when is_atom(scope) do
    scope in get_scopes()
  end

  @spec has_app_access?(binary, atom | binary) :: boolean
  def has_app_access?(scope, rule) do
    Logger.debug("Has app token access? scope: #{inspect(scope)}, rule: #{inspect(rule)}")
    scope = String.split(scope, " ")
    scope_acceptable_for_rule?(scope, rule) or global_scopes_acceptable_for_rule?(scope, rule)
  end

  @spec scope_acceptable_for_rule?(list(String.t() | atom()), String.t() | atom()) :: boolean()
  defp scope_acceptable_for_rule?(scope, rule) when is_list(scope) do
    to_string(rule) in Enum.map(scope, &to_string/1)
  end

  defp global_scopes_acceptable_for_rule?(scope, rule),
    do: Enum.any?(scope, &global_scope_acceptable_for_rule?(&1, rule))

  defp global_scope_acceptable_for_rule?(global_scope, rule),
    do: scope_acceptable_for_rule?(Map.get(@global_scope, global_scope, []), rule)
end
