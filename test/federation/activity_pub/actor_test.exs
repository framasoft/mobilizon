defmodule Mobilizon.Federation.ActivityPub.ActorTest do
  use Mobilizon.DataCase
  import Mox
  import Mock

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.HTTP.ActivityPub.Mock
  alias Mobilizon.Service.HTTP.HostMetaClient.Mock, as: HostMetaClientMock
  alias Mobilizon.Service.HTTP.WebfingerClient.Mock, as: WebfingerClientMock

  describe "fetching actor from its url" do
    @actor_url "https://framapiaf.org/users/tcit"
    test "returns an actor from nickname" do
      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", @actor_url)
        |> Map.put("preferredUsername", "tcit")
        |> Map.put("discoverable", true)

      Mock
      |> expect(:call, fn
        %{method: :get, url: @actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://framapiaf.org/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 404, body: ""}}
      end)

      webfinger_data =
        File.read!("test/fixtures/webfinger/mastodon-webfinger.json")
        |> String.replace("social.tcit.fr", "framapiaf.org")
        |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "http://framapiaf.org/.well-known/webfinger?resource=acct:tcit@framapiaf.org"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      assert {:ok,
              %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :public} =
                _actor} = ActivityPubActor.make_actor_from_nickname("tcit@framapiaf.org")
    end

    test "returns an actor from nickname when not discoverable" do
      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", @actor_url)
        |> Map.put("preferredUsername", "tcit")

      Mock
      |> expect(:call, fn
        %{method: :get, url: @actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      HostMetaClientMock
      |> expect(:call, fn
        %{method: :get, url: "http://framapiaf.org/.well-known/host-meta"}, _opts ->
          {:ok, %Tesla.Env{status: 404, body: ""}}
      end)

      webfinger_data =
        File.read!("test/fixtures/webfinger/mastodon-webfinger.json")
        |> String.replace("social.tcit.fr", "framapiaf.org")
        |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "http://framapiaf.org/.well-known/webfinger?resource=acct:tcit@framapiaf.org"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: webfinger_data}}
      end)

      assert {:ok,
              %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :unlisted} =
                _actor} = ActivityPubActor.make_actor_from_nickname("tcit@framapiaf.org")
    end

    test "returns an actor from url" do
      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", @actor_url)
        |> Map.put("preferredUsername", "tcit")

      Mock
      |> expect(:call, fn
        %{method: :get, url: @actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      # Initial fetch
      # Unlisted because discoverable is not present in the JSON payload
      assert {:ok,
              %Actor{preferred_username: "tcit", domain: "framapiaf.org", visibility: :unlisted}} =
               ActivityPubActor.get_or_fetch_actor_by_url(@actor_url)

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
         make_actor_from_url: fn @actor_url, preload: false ->
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
        refute called(ActivityPubActor.make_actor_from_url(@actor_url, preload: false))
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
         make_actor_from_url: fn @actor_url, preload: false ->
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
        assert_called(ActivityPubActor.make_actor_from_url(@actor_url, preload: false))
      end
    end

    test "handles remote actor being deleted" do
      Mock
      |> expect(:call, fn
        %{method: :get, url: @actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 410, body: ""}}
      end)

      assert match?(
               {:error, :actor_deleted},
               ActivityPubActor.make_actor_from_url(@actor_url, preload: false)
             )
    end

    @public_url "https://www.w3.org/ns/activitystreams#Public"
    test "activitystreams#Public uri returns Relay actor" do
      assert ActivityPubActor.get_or_fetch_actor_by_url(@public_url) == {:ok, Relay.get_actor()}
    end
  end
end
