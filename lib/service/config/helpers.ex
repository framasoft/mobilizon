defmodule Mobilizon.Service.Config.Helpers do
  @moduledoc """
  Provide some helpers to configuration files
  """

  @spec host_from_uri(String.t() | nil) :: String.t() | nil
  def host_from_uri(nil), do: nil

  def host_from_uri(uri) when is_binary(uri) do
    URI.parse(uri).host
  end
end
