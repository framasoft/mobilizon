defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.AcceptTest do
  use Mobilizon.DataCase

  import Mox
  alias Mobilizon.Federation.ActivityPub.Transmogrifier
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "Receiving an Accept Join Event activity from a foreign instance" do
    @base_actor_data File.read!("test/fixtures/mastodon-actor.json")
                     |> Jason.decode!()
    @actor_url "https://mobilizon.extinctionrebellion.fr/@anonymous"
    @actor_data @base_actor_data
                |> Map.put("id", @actor_url)
                |> Map.put("preferredUsername", "anonymous")

    @osmi_actor_url "https://mobilizon.extinctionrebellion.fr/@osmi"
    @osmi_actor_data @base_actor_data
                     |> Map.put("id", @osmi_actor_url)
                     |> Map.put("preferredUsername", "osmi")

    @xr_nantes_actor_url "https://mobilizon.extinctionrebellion.fr/@xr_nantes"
    @xr_nantes_actor_data @base_actor_data
                          |> Map.put("id", @xr_nantes_actor_url)
                          |> Map.put("preferredUsername", "xr_nantes")

    @event_url "https://mobilizon.extinctionrebellion.fr/events/d70f8e0d-62dc-4897-a855-ebcbe9798fc1"
    @event_data File.read!("test/fixtures/mobilizon-post-activity.json")
                |> Jason.decode!()
                |> Map.get("object")
                |> Map.put("id", @event_url)
                |> Map.put("actor", @osmi_actor_url)
                |> Map.put("attributedTo", @xr_nantes_actor_url)
                |> Map.put("tag", [])

    test "When the event is remote" do
      object = %{
        "actor" => @actor_url,
        "id" =>
          "https://mobilizon.extinctionrebellion.fr/join/event/b67cf172-af23-4ae8-b00e-a2e3643ccb21",
        "object" =>
          "https://mobilizon.extinctionrebellion.fr/events/d70f8e0d-62dc-4897-a855-ebcbe9798fc1",
        "participationMessage" => nil,
        "published" => "2022-03-28T20:11:11Z",
        "type" => "Join"
      }

      activity = %{
        "type" => "Accept",
        "object" => object,
        "actor" => @actor_url,
        "id" =>
          "https://mobilizon.extinctionrebellion.fr/join/event/b67cf172-af23-4ae8-b00e-a2e3643ccb21/activity"
      }

      Mock
      |> expect(:call, 4, fn
        %{method: :get, url: @actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: @actor_data}}

        %{method: :get, url: @osmi_actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: @osmi_actor_data}}

        %{method: :get, url: @xr_nantes_actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: @xr_nantes_actor_data}}

        %{method: :get, url: @event_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: @event_data}}
      end)

      assert {:ok, _activity, _object} = Transmogrifier.handle_incoming(activity)
    end
  end
end
