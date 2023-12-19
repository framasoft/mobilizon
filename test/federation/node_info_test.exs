defmodule Mobilizon.Federation.NodeInfoTest do
  use Mobilizon.DataCase
  import Mox

  alias Mobilizon.Federation.NodeInfo
  alias Mobilizon.Service.HTTP.WebfingerClient.Mock, as: WebfingerClientMock

  @instance_domain "event-federation.eu"
  @nodeinfo_fixture_path "test/fixtures/nodeinfo/wp-event-federation.json"
  @nodeinfo_regular_fixture_path "test/fixtures/nodeinfo/regular.json"

  describe "getting application actor" do
    test "from wordpress event federation" do
      nodeinfo_data = @nodeinfo_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://event-federation.eu/.well-known/nodeinfo"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: nodeinfo_data}}
      end)

      assert "https://event-federation.eu/actor-relay" ==
               NodeInfo.application_actor(@instance_domain)
    end

    test "with no FEP-2677 information" do
      nodeinfo_data = @nodeinfo_regular_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://event-federation.eu/.well-known/nodeinfo"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: nodeinfo_data}}
      end)

      assert nil == NodeInfo.application_actor(@instance_domain)
    end

    test "with no result" do
      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://event-federation.eu/.well-known/nodeinfo"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 404, body: ""}}
      end)

      assert nil == NodeInfo.application_actor(@instance_domain)
    end
  end
end
