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

  @doc """
  Generate RSA 2048-bit private key.
  """
  @spec generate_rsa_2048_private_key :: String.t()
  def generate_rsa_2048_private_key do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)

    [entry]
    |> :public_key.pem_encode()
    |> String.trim_trailing()
  end
end
