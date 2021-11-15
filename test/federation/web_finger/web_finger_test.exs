# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/web_finger/web_finger_test.exs

defmodule Mobilizon.Federation.WebFingerTest do
  use Mobilizon.DataCase
  import Mox
  import Mobilizon.Factory

  alias Mobilizon.Federation.WebFinger
  alias Mobilizon.Service.HTTP.HostMetaClient.Mock, as: HostMetaClientMock
  alias Mobilizon.Service.HTTP.WebfingerClient.Mock, as: WebfingerClientMock
  alias Mobilizon.Web.Endpoint

  @mastodon_account "tcit@social.tcit.fr"
  @mastodon_account_username "tcit"
  @pleroma_account "lain@pleroma.soykaf.com"
  @pleroma_account_username "lain"
  @peertube_account "framasoft@framatube.org"
  @peertube_account_username "framasoft"
  @friendica_account "lain@squeet.me"
  @friendica_account_username "lain"
  @gancio_account "gancio@demo.gancio.org"
  @gancio_account_username "gancio"

  describe "host meta" do
    test "returns a link to the xml lrdd" do
      host_info = WebFinger.host_meta()

      assert String.contains?(host_info, Endpoint.url())
    end
  end

  describe "incoming webfinger request" do
    test "works for fqns" do
      actor = insert(:actor)

      {:ok, result} =
        WebFinger.webfinger(
          "#{actor.preferred_username}@#{Endpoint.host()}",
          "JSON"
        )

      assert is_map(result)
    end

    test "works for urls" do
      actor = insert(:actor)

      {:ok, result} = WebFinger.webfinger(actor.url, "JSON")
      assert is_map(result)
    end
  end

  describe "fingering" do
    test "a mastodon actor" do
      host_meta_xml = File.read!("test/fixtures/webfinger/mastodon-host-meta.xml")

      webfinger_data =
        File.read!("test/fixtures/webfinger/mastodon-webfinger.json") |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://social.tcit.fr/.well-known/webfinger?resource=acct:tcit@social.tcit.fr"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://social.tcit.fr/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: host_meta_xml}}
      end)

      res = "https://social.tcit.fr/users/#{@mastodon_account_username}"

      assert {:ok, res} == WebFinger.finger(@mastodon_account)
    end

    test "a pleroma actor" do
      host_meta_xml = File.read!("test/fixtures/webfinger/pleroma-host-meta.xml")

      webfinger_data =
        File.read!("test/fixtures/webfinger/pleroma-webfinger.json") |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://pleroma.soykaf.com/.well-known/webfinger?resource=acct:lain@pleroma.soykaf.com"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://pleroma.soykaf.com/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: host_meta_xml}}
      end)

      res = "https://pleroma.soykaf.com/users/#{@pleroma_account_username}"

      assert {:ok, res} == WebFinger.finger(@pleroma_account)
    end

    test "a peertube actor" do
      host_meta_xml = File.read!("test/fixtures/webfinger/peertube-host-meta.xml")

      webfinger_data =
        File.read!("test/fixtures/webfinger/peertube-webfinger.json") |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://framatube.org/.well-known/webfinger?resource=acct:framasoft@framatube.org"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://framatube.org/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: host_meta_xml}}
      end)

      res = "https://framatube.org/accounts/#{@peertube_account_username}"

      assert {:ok, res} == WebFinger.finger(@peertube_account)
    end

    test "a friendica actor" do
      host_meta_xml = File.read!("test/fixtures/webfinger/friendica-host-meta.xml")

      webfinger_data =
        File.read!("test/fixtures/webfinger/friendica-webfinger.json") |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://squeet.me/.well-known/webfinger?resource=acct:lain@squeet.me"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://squeet.me/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: host_meta_xml}}
      end)

      res = "https://squeet.me/profile/#{@friendica_account_username}"

      assert {:ok, res} == WebFinger.finger(@friendica_account)
    end

    test "a Gancio actor" do
      host_meta_xml = File.read!("test/fixtures/webfinger/gancio-host-meta.xml")

      webfinger_data =
        File.read!("test/fixtures/webfinger/gancio-webfinger.json") |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url:
            "https://demo.gancio.org/.well-known/webfinger?resource=acct:gancio@demo.gancio.org"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://demo.gancio.org/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: host_meta_xml}}
      end)

      res = "https://demo.gancio.org/federation/u/#{@gancio_account_username}"

      assert {:ok, res} == WebFinger.finger(@gancio_account)
    end
  end
end
