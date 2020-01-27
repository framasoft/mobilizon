# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/media_proxy_test.ex

defmodule Mobilizon.Web.MediaProxyTest do
  use ExUnit.Case

  import Mobilizon.Web.MediaProxy

  alias Mobilizon.Config

  alias Mobilizon.Web.MediaProxyController

  setup do
    enabled = Config.get([:media_proxy, :enabled])
    on_exit(fn -> Config.put([:media_proxy, :enabled], enabled) end)
    :ok
  end

  describe "when enabled" do
    setup do
      Config.put([:media_proxy, :enabled], true)
      :ok
    end

    test "ignores invalid url" do
      assert url(nil) == nil
      assert url("") == nil
    end

    test "ignores relative url" do
      assert url("/local") == "/local"
      assert url("/") == "/"
    end

    test "ignores local url" do
      local_url = Mobilizon.Web.Endpoint.url() <> "/hello"
      local_root = Mobilizon.Web.Endpoint.url()
      assert url(local_url) == local_url
      assert url(local_root) == local_root
    end

    test "encodes and decodes URL" do
      url = "https://pleroma.soykaf.com/static/logo.png"
      encoded = url(url)

      assert String.starts_with?(
               encoded,
               Config.get([:media_proxy, :base_url], Mobilizon.Web.Endpoint.url())
             )

      assert String.ends_with?(encoded, "/logo.png")

      assert decode_result(encoded) == url
    end

    test "encodes and decodes URL without a path" do
      url = "https://pleroma.soykaf.com"
      encoded = url(url)
      assert decode_result(encoded) == url
    end

    test "encodes and decodes URL without an extension" do
      url = "https://pleroma.soykaf.com/path/"
      encoded = url(url)
      assert String.ends_with?(encoded, "/path")
      assert decode_result(encoded) == url
    end

    test "encodes and decodes URL and ignores query params for the path" do
      url = "https://pleroma.soykaf.com/static/logo.png?93939393939&bunny=true"
      encoded = url(url)
      assert String.ends_with?(encoded, "/logo.png")
      assert decode_result(encoded) == url
    end

    test "ensures urls are url-encoded" do
      assert decode_result(url("https://pleroma.social/Hello world.jpg")) ==
               "https://pleroma.social/Hello%20world.jpg"

      assert decode_result(url("https://pleroma.social/Hello%20world.jpg")) ==
               "https://pleroma.social/Hello%20world.jpg"
    end

    test "validates signature" do
      secret_key_base = Config.get([Mobilizon.Web.Endpoint, :secret_key_base])

      on_exit(fn ->
        Config.put([Mobilizon.Web.Endpoint, :secret_key_base], secret_key_base)
      end)

      encoded = url("https://pleroma.social")

      Config.put(
        [Mobilizon.Web.Endpoint, :secret_key_base],
        "00000000000000000000000000000000000000000000000"
      )

      [_, "proxy", sig, base64 | _] = URI.parse(encoded).path |> String.split("/")
      assert decode_url(sig, base64) == {:error, :invalid_signature}
    end

    test "filename_matches matches url encoded paths" do
      assert MediaProxyController.filename_matches(
               true,
               "/Hello%20world.jpg",
               "http://pleroma.social/Hello world.jpg"
             ) == :ok

      assert MediaProxyController.filename_matches(
               true,
               "/Hello%20world.jpg",
               "http://pleroma.social/Hello%20world.jpg"
             ) == :ok
    end

    test "filename_matches matches non-url encoded paths" do
      assert MediaProxyController.filename_matches(
               true,
               "/Hello world.jpg",
               "http://pleroma.social/Hello%20world.jpg"
             ) == :ok

      assert MediaProxyController.filename_matches(
               true,
               "/Hello world.jpg",
               "http://pleroma.social/Hello world.jpg"
             ) == :ok
    end

    test "uses the configured base_url" do
      base_url = Config.get([:media_proxy, :base_url])

      if base_url do
        on_exit(fn ->
          Config.put([:media_proxy, :base_url], base_url)
        end)
      end

      Config.put([:media_proxy, :base_url], "https://cache.pleroma.social")

      url = "https://pleroma.soykaf.com/static/logo.png"
      encoded = url(url)

      assert String.starts_with?(encoded, Config.get([:media_proxy, :base_url]))
    end

    # https://git.pleroma.social/pleroma/pleroma/issues/580
    test "encoding S3 links (must preserve `%2F`)" do
      url =
        "https://s3.amazonaws.com/example/test.png?X-Amz-Credential=your-access-key-id%2F20130721%2Fus-east-1%2Fs3%2Faws4_request"

      encoded = url(url)
      assert decode_result(encoded) == url
    end
  end

  describe "when disabled" do
    setup do
      enabled = Config.get([:media_proxy, :enabled])

      if enabled do
        Config.put([:media_proxy, :enabled], false)

        on_exit(fn ->
          Config.put([:media_proxy, :enabled], enabled)
          :ok
        end)
      end

      :ok
    end

    test "does not encode remote urls" do
      assert url("https://google.fr") == "https://google.fr"
    end
  end

  defp decode_result(encoded) do
    [_, "proxy", sig, base64 | _] = URI.parse(encoded).path |> String.split("/")
    {:ok, decoded} = decode_url(sig, base64)
    decoded
  end
end
