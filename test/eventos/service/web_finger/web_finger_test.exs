defmodule Eventos.Service.WebFingerTest do
  use Eventos.DataCase
  alias Eventos.Service.WebFinger
  import Eventos.Factory

  describe "host meta" do
    test "returns a link to the xml lrdd" do
      host_info = WebFinger.host_meta()

      assert String.contains?(host_info, EventosWeb.Endpoint.url())
    end
  end

  describe "incoming webfinger request" do
    test "works for fqns" do
      account = insert(:account)

      {:ok, result} =
        WebFinger.webfinger("#{account.username}@#{EventosWeb.Endpoint.host()}", "JSON")
      assert is_map(result)
    end

    test "works for urls" do
      account = insert(:account)

      {:ok, result} = WebFinger.webfinger(account.url, "JSON")
      assert is_map(result)
    end
  end

  describe "fingering" do

    test "a mastodon account" do
      account = "tcit@social.tcit.fr"

      assert {:ok, %{"subject" => "acct:" <> account, "url" => "https://social.tcit.fr/users/tcit"}} = WebFinger.finger(account)
    end

    test "a pleroma account" do
      account = "@lain@pleroma.soykaf.com"

      assert {:ok, %{"subject" => "acct:" <> account, "url" => "https://pleroma.soykaf.com/users/lain"}} = WebFinger.finger(account)
    end

    test "a peertube account" do
      account = "framasoft@framatube.org"

      assert {:ok, %{"subject" => "acct:" <> account, "url" => "https://framatube.org/accounts/framasoft"}} = WebFinger.finger(account)
    end

    test "a friendica account" do
      # Hasn't any ActivityPub
      account = "lain@squeet.me"

      assert {:ok, %{"subject" => "acct:" <> account} = data} = WebFinger.finger(account)
      refute Map.has_key?(data, "url")
    end
  end
end
