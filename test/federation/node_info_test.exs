defmodule Mobilizon.Federation.NodeInfoTest do
  use Mobilizon.DataCase
  import Mox

  alias Mobilizon.Federation.NodeInfo
  alias Mobilizon.Service.HTTP.WebfingerClient.Mock, as: WebfingerClientMock

  @instance_domain "event-federation.eu"
  @nodeinfo_fixture_path "test/fixtures/nodeinfo/wp-event-federation.json"
  @nodeinfo_regular_fixture_path "test/fixtures/nodeinfo/regular.json"
  @nodeinfo_both_versions_fixture_path "test/fixtures/nodeinfo/both_versions.json"
  @nodeinfo_older_versions_fixture_path "test/fixtures/nodeinfo/older_versions.json"
  @nodeinfo_data_fixture_path "test/fixtures/nodeinfo/data.json"
  @nodeinfo_wp_data_fixture_path "test/fixtures/nodeinfo/wp-data.json"

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
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_data,
             headers: [{"content-type", "application/json"}]
           }}
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

  describe "getting informations" do
    test "with both 2.0 and 2.1 endpoints" do
      nodeinfo_end_point_data =
        @nodeinfo_both_versions_fixture_path |> File.read!() |> Jason.decode!()

      nodeinfo_data = @nodeinfo_data_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://mobilizon.fr/.well-known/nodeinfo"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_end_point_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://mobilizon.fr/.well-known/nodeinfo/2.1"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      assert {:ok, data} = NodeInfo.nodeinfo("mobilizon.fr")
      assert data["version"] == "2.1"
      assert data["software"]["name"] == "Mobilizon"
      # Added in 2.1
      refute is_nil(data["software"]["repository"])
    end

    test "with only 2.0 endpoint" do
      nodeinfo_end_point_data = @nodeinfo_regular_fixture_path |> File.read!() |> Jason.decode!()
      nodeinfo_wp_data = @nodeinfo_wp_data_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://event-federation.eu/.well-known/nodeinfo"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_end_point_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://event-federation.eu/wp-json/activitypub/1.0/nodeinfo"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_wp_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      assert {:ok, data} = NodeInfo.nodeinfo("event-federation.eu")
      assert data["version"] == "2.0"
      assert data["software"]["name"] == "wordpress"
      # Added in 2.1
      assert is_nil(data["software"]["repository"])
    end

    test "with no valid endpoint" do
      nodeinfo_end_point_data =
        @nodeinfo_older_versions_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://somewhere.tld/.well-known/nodeinfo"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_end_point_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      assert {:error, :no_node_info_endpoint_found} = NodeInfo.nodeinfo("somewhere.tld")
    end

    test "with no answer from well-known endpoint" do
      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://somewhere.tld/.well-known/nodeinfo"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 404}}
      end)

      assert {:error, :node_info_meta_http_error} = NodeInfo.nodeinfo("somewhere.tld")
    end

    test "with no answer from version endpoint" do
      nodeinfo_end_point_data =
        @nodeinfo_both_versions_fixture_path |> File.read!() |> Jason.decode!()

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://mobilizon.fr/.well-known/nodeinfo"
        },
        _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body: nodeinfo_end_point_data,
             headers: [{"content-type", "application/json"}]
           }}
      end)

      WebfingerClientMock
      |> expect(:call, fn
        %{
          method: :get,
          url: "https://mobilizon.fr/.well-known/nodeinfo/2.1"
        },
        _opts ->
          {:ok, %Tesla.Env{status: 404}}
      end)

      assert {:error, :node_info_endpoint_http_error} = NodeInfo.nodeinfo("mobilizon.fr")
    end
  end
end
