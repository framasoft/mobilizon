defmodule Mobilizon.Service.WebFingerTest do
  use Mobilizon.DataCase
  alias Mobilizon.Service.WebFinger
  import Mobilizon.Factory

  describe "host meta" do
    test "returns a link to the xml lrdd" do
      host_info = WebFinger.host_meta()

      assert String.contains?(host_info, MobilizonWeb.Endpoint.url())
    end
  end

  describe "incoming webfinger request" do
    test "works for fqns" do
      actor = insert(:actor)

      {:ok, result} =
        WebFinger.webfinger("#{actor.preferred_username}@#{MobilizonWeb.Endpoint.host()}", "JSON")

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
      actor = "tcit@social.tcit.fr"

      assert {:ok, %{"subject" => "acct:" <> actor, "url" => "https://social.tcit.fr/users/tcit"}} =
               WebFinger.finger(actor)
    end

    test "a pleroma actor" do
      actor = "@lain@pleroma.soykaf.com"

      assert {:ok,
              %{"subject" => "acct:" <> actor, "url" => "https://pleroma.soykaf.com/users/lain"}} =
               WebFinger.finger(actor)
    end

    test "a peertube actor" do
      actor = "framasoft@framatube.org"

      assert {:ok,
              %{
                "subject" => "acct:" <> actor,
                "url" => "https://framatube.org/accounts/framasoft"
              }} = WebFinger.finger(actor)
    end

    test "a friendica actor" do
      # Now with ActivityPub !
      actor = "lain@squeet.me"

      assert {:ok,
              %{
                "subject" => "acct:" <> actor,
                "url" => "https://squeet.me/profile/lain"
              }} = WebFinger.finger(actor)
    end
  end
end
