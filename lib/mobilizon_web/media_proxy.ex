# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/media_proxy/media_proxy.ex

defmodule MobilizonWeb.MediaProxy do
  @moduledoc """
  Handles proxifying media files
  """

  alias Mobilizon.Config

  @base64_opts [padding: false]

  def url(nil), do: nil

  def url(""), do: nil

  def url("/" <> _ = url), do: url

  def url(url) do
    config = Application.get_env(:mobilizon, :media_proxy, [])

    if !Keyword.get(config, :enabled, false) or
         String.starts_with?(url, MobilizonWeb.Endpoint.url()) do
      url
    else
      encode_url(url)
    end
  end

  def encode_url(url) do
    secret = Application.get_env(:mobilizon, MobilizonWeb.Endpoint)[:secret_key_base]

    # Must preserve `%2F` for compatibility with S3
    # https://git.pleroma.social/pleroma/pleroma/issues/580
    replacement = get_replacement(url, ":2F:")

    # The URL is url-decoded and encoded again to ensure it is correctly encoded and not twice.
    base64 =
      url
      |> String.replace("%2F", replacement)
      |> URI.decode()
      |> URI.encode()
      |> String.replace(replacement, "%2F")
      |> Base.url_encode64(@base64_opts)

    sig = :crypto.hmac(:sha, secret, base64)
    sig64 = sig |> Base.url_encode64(@base64_opts)

    build_url(sig64, base64, filename(url))
  end

  def decode_url(sig, url) do
    secret = Application.get_env(:mobilizon, MobilizonWeb.Endpoint)[:secret_key_base]
    sig = Base.url_decode64!(sig, @base64_opts)
    local_sig = :crypto.hmac(:sha, secret, url)

    if local_sig == sig do
      {:ok, Base.url_decode64!(url, @base64_opts)}
    else
      {:error, :invalid_signature}
    end
  end

  def filename(url_or_path) do
    if path = URI.parse(url_or_path).path, do: Path.basename(path)
  end

  def build_url(sig_base64, url_base64, filename \\ nil) do
    [
      Config.get([:media_proxy, :base_url], MobilizonWeb.Endpoint.url()),
      "proxy",
      sig_base64,
      url_base64,
      filename
    ]
    |> Enum.filter(fn value -> value end)
    |> Path.join()
  end

  defp get_replacement(url, replacement) do
    if String.contains?(url, replacement) do
      get_replacement(url, replacement <> replacement)
    else
      replacement
    end
  end
end
