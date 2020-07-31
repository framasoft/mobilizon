defmodule Mobilizon.Service.Guards do
  @moduledoc """
  Various guards
  """

  defguard is_nil_or_empty_string(value) when is_nil(value) or value == ""
end
