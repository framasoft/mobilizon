defmodule Mobilizon.Service.HTTP.Utils do
  @moduledoc """
  Utils for HTTP operations
  """

  def get_tls_config do
    cacertfile =
      if is_nil(System.get_env("MOBILIZON_CA_CERT_PATH")) do
        CAStore.file_path()
      else
        System.get_env("MOBILIZON_CA_CERT_PATH")
      end

    [cacertfile: cacertfile]
  end

  @spec get_header(Enum.t(), String.t()) :: String.t() | nil
  def get_header(headers, key) do
    key = String.downcase(key)

    case List.keyfind(headers, key, 0) do
      {^key, value} -> String.downcase(value)
      nil -> nil
    end
  end

  @spec content_type_matches?(Enum.t(), String.t() | list(String.t())) :: boolean
  def content_type_matches?(headers, content_type) do
    headers
    |> get_header("Content-Type")
    |> content_type_header_matches(content_type)
  end

  @spec content_type_header_matches(String.t() | nil, Enum.t()) :: boolean
  defp content_type_header_matches(header, content_types)
  defp content_type_header_matches(nil, _content_types), do: false

  defp content_type_header_matches(header, content_type)
       when is_binary(header) and is_binary(content_type),
       do: content_type_header_matches(header, [content_type])

  defp content_type_header_matches(header, content_types)
       when is_binary(header) and is_list(content_types) do
    Enum.any?(content_types, fn content_type -> String.starts_with?(header, content_type) end)
  end
end
