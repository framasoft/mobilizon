defmodule Mobilizon.Service.Guards do
  @moduledoc """
  Various guards
  """

  defguard is_valid_string?(value) when is_binary(value) and value != ""

  defguard is_valid_list?(value) when is_list(value) and length(value) > 0
end
