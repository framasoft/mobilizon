defmodule Mobilizon.Users.Guards do
  @moduledoc """
  Guards for users
  """

  defguard is_admin(role) when is_atom(role) and role == :administrator

  defguard is_moderator(role) when is_atom(role) and role in [:administrator, :moderator]
end
