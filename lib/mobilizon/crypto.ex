defmodule Mobilizon.Crypto do
  @moduledoc """
  Utility module which contains cryptography related functions.
  """

  @doc """
  Returns random byte sequence of the length encoded to Base64.
  """
  @spec random_string(integer) :: String.t()
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end
end
