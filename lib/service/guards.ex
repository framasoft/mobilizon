defmodule Mobilizon.Service.Guards do
  @moduledoc """
  Various guards
  """

  @doc """
  Returns `true` if `term` is a valid string and not empty.

  ## Examples

      iex> is_valid_string("one")
      true
      iex> is_valid_string("")
      false
      iex> is_valid_string(2)
      false
  """
  defguard is_valid_string(term) when is_binary(term) and term != ""

  @doc """
  Returns `true` if `term` is a valid list and not empty.

  ## Examples

      iex> is_valid_list(["one"])
      true
      iex> is_valid_list([])
      false
      iex> is_valid_list("foo")
      false
  """
  defguard is_valid_list(term) when is_list(term) and length(term) > 0
end
