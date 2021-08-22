defmodule Mobilizon.Storage.CustomFunctions do
  @moduledoc """
  Helper module for custom PostgreSQL functions
  """
  defmacro split_part(string, delimiter, position) do
    quote do
      fragment("split_part(?, ?, ?)", unquote(string), unquote(delimiter), unquote(position))
    end
  end
end
