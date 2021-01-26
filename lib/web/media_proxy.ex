# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.MediaProxy do
  @moduledoc """
  Module to proxify remote media
  """
  alias Mobilizon.Config
  alias Mobilizon.Web

  @base64_opts [padding: false]

  def url(url) when is_nil(url) or url == "", do: nil
  def url("/" <> _ = url), do: url

  def url(url) do
    if enabled?() and url_proxiable?(url) do
      encode_url(url)
    else
      url
    end
  end

  @spec url_proxiable?(String.t()) :: boolean()
  def url_proxiable?(url) do
    not local?(url)
  end

  def enabled?, do: Config.get([:media_proxy, :enabled], false)

  # Note: media proxy must be enabled for media preview proxy in order to load all
  #   non-local non-whitelisted URLs through it and be sure that body size constraint is preserved.
  def preview_enabled?, do: enabled?() and !!Config.get([:media_preview_proxy, :enabled])

  def local?(url), do: String.starts_with?(url, Web.Endpoint.url())

  defp base64_sig64(url) do
    base64 = Base.url_encode64(url, @base64_opts)

    sig64 =
      base64
      |> signed_url()
      |> Base.url_encode64(@base64_opts)

    {base64, sig64}
  end

  def encode_url(url) do
    {base64, sig64} = base64_sig64(url)

    build_url(sig64, base64, filename(url))
  end

  def decode_url(sig, url) do
    with {:ok, sig} <- Base.url_decode64(sig, @base64_opts),
         signature when signature == sig <- signed_url(url) do
      {:ok, Base.url_decode64!(url, @base64_opts)}
    else
      _ -> {:error, :invalid_signature}
    end
  end

  defp signed_url(url) do
    :crypto.hmac(:sha, Config.get([Web.Endpoint, :secret_key_base]), url)
  end

  def filename(url_or_path) do
    if path = URI.parse(url_or_path).path, do: Path.basename(path)
  end

  def base_url do
    Web.Endpoint.url()
  end

  defp proxy_url(path, sig_base64, url_base64, filename) do
    [
      base_url(),
      path,
      sig_base64,
      url_base64,
      filename
    ]
    |> Enum.filter(& &1)
    |> Path.join()
  end

  def build_url(sig_base64, url_base64, filename \\ nil) do
    proxy_url("proxy", sig_base64, url_base64, filename)
  end

  def verify_request_path_and_url(
        %Plug.Conn{params: %{"filename" => _}, request_path: request_path},
        url
      ) do
    verify_request_path_and_url(request_path, url)
  end

  def verify_request_path_and_url(request_path, url) when is_binary(request_path) do
    filename = filename(url)

    if filename && not basename_matches?(request_path, filename) do
      {:wrong_filename, filename}
    else
      :ok
    end
  end

  def verify_request_path_and_url(_, _), do: :ok

  defp basename_matches?(path, filename) do
    basename = Path.basename(path)
    basename == filename or URI.decode(basename) == filename or URI.encode(basename) == filename
  end
end
