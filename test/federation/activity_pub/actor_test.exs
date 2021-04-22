defmodule Mobilizon.Federation.ActivityPub.ActorTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Mobilizon.DataCase

  import Mock

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.{Fetcher, Relay}

  describe "fetching actor from its url" do
    test "returns an actor from nickname" do
      use_cassette "activity_pub/fetch_tcit@framapiaf.org" do
        assert {:ok,
                %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :public} =
                  _actor} = ActivityPubActor.make_actor_from_nickname("tcit@framapiaf.org")
      end

      use_cassette "activity_pub/fetch_tcit@framapiaf.org_not_discoverable" do
        assert {:ok,
                %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :unlisted} =
                  _actor} = ActivityPubActor.make_actor_from_nickname("tcit@framapiaf.org")
      end
    end

    @actor_url "https://framapiaf.org/users/tcit"
    test "returns an actor from url" do
      # Initial fetch
      use_cassette "activity_pub/fetch_framapiaf.org_users_tcit" do
        # Unlisted because discoverable is not present in the JSON payload
        assert {:ok,
                %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :unlisted}} =
                 ActivityPubActor.get_or_fetch_actor_by_url(@actor_url)
      end

      # Fetch uses cache if Actors.needs_update? returns false
      with_mocks([
        {Actors, [:passthrough],
         [
           get_actor_by_url: fn @actor_url, false ->
             {:ok,
              %Actor{
                preferred_username: "tcit",
                domain: "framapiaf.org"
              }}
           end,
           needs_update?: fn _ -> false end
         ]},
        {ActivityPubActor, [:passthrough],
         make_actor_from_url: fn @actor_url, false ->
           {:ok,
            %Actor{
              preferred_username: "tcit",
              domain: "framapiaf.org"
            }}
         end}
      ]) do
        assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"}} =
                 ActivityPubActor.get_or_fetch_actor_by_url(@actor_url)

        assert_called(Actors.needs_update?(:_))
        refute called(ActivityPubActor.make_actor_from_url(@actor_url, false))
      end

      # Fetch doesn't use cache if Actors.needs_update? returns true
      with_mocks([
        {Actors, [:passthrough],
         [
           get_actor_by_url: fn @actor_url, false ->
             {:ok,
              %Actor{
                preferred_username: "tcit",
                domain: "framapiaf.org"
              }}
           end,
           needs_update?: fn _ -> true end
         ]},
        {ActivityPubActor, [:passthrough],
         make_actor_from_url: fn @actor_url, false ->
           {:ok,
            %Actor{
              preferred_username: "tcit",
              domain: "framapiaf.org"
            }}
         end}
      ]) do
        assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"}} =
                 ActivityPubActor.get_or_fetch_actor_by_url(@actor_url)

        assert_called(ActivityPubActor.get_or_fetch_actor_by_url(@actor_url))
        assert_called(Actors.get_actor_by_url(@actor_url, false))
        assert_called(Actors.needs_update?(:_))
        assert_called(ActivityPubActor.make_actor_from_url(@actor_url, false))
      end
    end

    test "handles remote actor being deleted" do
      with_mocks([
        {Fetcher, [:passthrough],
         fetch_and_prepare_actor_from_url: fn @actor_url ->
           {:error, :actor_deleted}
         end}
      ]) do
        assert match?(
                 {:error, :actor_deleted},
                 ActivityPubActor.make_actor_from_url(@actor_url, false)
               )

        assert_called(Fetcher.fetch_and_prepare_actor_from_url(@actor_url))
      end
    end

    @public_url "https://www.w3.org/ns/activitystreams#Public"
    test "activitystreams#Public uri returns Relay actor" do
      assert ActivityPubActor.get_or_fetch_actor_by_url(@public_url) == {:ok, Relay.get_actor()}
    end
  end
end
