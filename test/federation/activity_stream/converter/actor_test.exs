defmodule Mobilizon.Federation.ActivityStream.Converter.ActorTest do
  use Mobilizon.DataCase

  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityStream.Converter.Actor, as: ActorConverter

  describe "actor to AS" do
    test "valid actor to as" do
      data = ActorConverter.model_to_as(%Actor{type: :Person, preferred_username: "test_account"})
      assert is_map(data)
      assert data["type"] == :Person
      assert data["preferredUsername"] == "test_account"
    end
  end

  describe "AS to Actor" do
    test "valid as data to model" do
      actor =
        ActorConverter.as_to_model_data(%{
          "id" => "https://somedomain.tld/users/someone",
          "type" => "Person",
          "preferredUsername" => "test_account"
        })

      assert actor.type == "Person"
      assert actor.preferred_username == "test_account"
    end
  end
end
