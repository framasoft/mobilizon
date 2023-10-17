defmodule Mobilizon.GraphQL.Authorization do
  @moduledoc """
  Check authorizations
  """

  use Rajska,
    valid_roles: [:user, :moderator, :administrator],
    super_role: :administrator,
    default_rule: :default

  alias Mobilizon.Applications.ApplicationToken
  alias Mobilizon.GraphQL.Authorization.AppScope
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  @impl true
  def has_user_access?(%User{}, _scope, _rule), do: true

  @impl true
  def has_user_access?(%ApplicationToken{scope: scope} = _current_app_token, _struct, rule)
      when rule != :forbid_app_access do
    AppScope.has_app_access?(scope, rule)
  end

  @impl true
  def has_user_access?(_current_user, _scoped_struct, _rule), do: false

  @impl true
  def get_current_user(%{current_auth_app_token: app_token}), do: app_token
  def get_current_user(%{current_user: current_user}), do: current_user
  def get_current_user(_ctx), do: nil

  @impl true
  def role_authorized?(_user_role, :all), do: true
  def role_authorized?(role, _allowed_role) when is_super_role(role), do: true
  def role_authorized?(:moderator, :user), do: true

  def role_authorized?(user_role, allowed_role) when is_atom(user_role) and is_atom(allowed_role),
    do: user_role === allowed_role

  def role_authorized?(user_role, allowed_roles)
      when is_atom(user_role) and is_list(allowed_roles),
      do: user_role in allowed_roles or (user_role === :moderator and :user in allowed_roles)

  @impl true
  def get_user_role(%ApplicationToken{user: %{role: role}}), do: role
  def get_user_role(%{role: role}), do: role
  def get_user_role(nil), do: nil

  @impl true
  def get_ip(%{ip: ip}), do: ip

  @impl true
  def unauthorized_message(resolution) do
    case Map.get(resolution.context, :current_user) do
      nil ->
        "unauthenticated"

      _ ->
        "unauthorized"
    end
  end

  @impl true
  def unauthorized_query_scope_message(_resolution, object_type) do
    dgettext("errors", "Not authorized to access this %{object_type}",
      object_type: replace_underscore(object_type)
    )
  end

  @impl true
  def unauthorized_object_scope_message(_result_object, object) do
    dgettext("errors", "Not authorized to access object %{object}", object: object.identifier)
  end

  @impl true
  def unauthorized_object_message(_resolution, object) do
    dgettext("errors", "Not authorized to access object %{object}", object: object.identifier)
  end

  @impl true
  def unauthorized_field_message(_resolution, field),
    do: dgettext("errors", "Not authorized to access field %{field}", field: field)

  defp replace_underscore(string) when is_binary(string), do: String.replace(string, "_", " ")

  defp replace_underscore(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> replace_underscore()
  end
end
