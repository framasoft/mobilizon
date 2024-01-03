defmodule Mobilizon.Service.Workers.RefreshInstancesTest do
  @moduledoc """
  Test the refresh instance module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.Workers.RefreshInstances

  use Mobilizon.DataCase

  describe "Refresh instance actor" do
    test "unless if local actor" do
      # relay = Mobilizon.Web.Relay.get_actor()
      assert {:error, :not_remote_instance} ==
               RefreshInstances.refresh_instance_actor(nil)
    end

    test "unless if local relay actor" do
      %Actor{url: url} = Relay.get_actor()
      %URI{host: domain} = URI.new!(url)

      assert {:error, :not_remote_instance} ==
               RefreshInstances.refresh_instance_actor(domain)
    end
  end
end
