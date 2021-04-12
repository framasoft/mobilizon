# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/web_finger/web_finger_test.exs

defmodule Mobilizon.Federation.WebFingerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Federation.WebFinger

  alias Mobilizon.Web.Endpoint

  @mastodon_account "tcit@social.tcit.fr"
  @mastodon_account_username "tcit"
  @pleroma_account "lain@pleroma.soykaf.com"
  @pleroma_account_username "lain"
  @peertube_account "framasoft@framatube.org"
  @peertube_account_username "framasoft"
  @friendica_account "lain@squeet.me"
  @friendica_account_username "lain"

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
      use_cassette "webfinger/mastodon" do
        res = "https://social.tcit.fr/users/#{@mastodon_account_username}"

        assert {:ok, res} == WebFinger.finger(@mastodon_account)
      end
    end

    test "a pleroma actor" do
      use_cassette "webfinger/pleroma" do
        res = "https://pleroma.soykaf.com/users/#{@pleroma_account_username}"

        assert {:ok, res} == WebFinger.finger(@pleroma_account)
      end
    end

    test "a peertube actor" do
      use_cassette "webfinger/peertube" do
        res = "https://framatube.org/accounts/#{@peertube_account_username}"

        assert {:ok, res} == WebFinger.finger(@peertube_account)
      end
    end

    test "a friendica actor" do
      use_cassette "webfinger/friendica" do
        res = "https://squeet.me/profile/#{@friendica_account_username}"

        assert {:ok, res} == WebFinger.finger(@friendica_account)
      end
    end
  end
end
