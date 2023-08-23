defmodule Mobilizon.Service.Export.Participants.CommonTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Export.Participants.Common
  import Mobilizon.Service.DateTime, only: [datetime_to_string: 1]

  test "convert participants to list items" do
    participant = insert(:participant)
    actor = insert(:actor)
    name = Actor.display_name_and_username(actor)
    date = datetime_to_string(participant.inserted_at)
    assert [^name, _, ^date, ""] = Common.to_list({participant, actor})
  end

  test "convert participants with metadata to list items" do
    participant = insert(:participant, metadata: %{message: "a message"})
    actor = insert(:actor)
    name = Actor.display_name_and_username(actor)
    date = datetime_to_string(participant.inserted_at)
    assert [^name, _, ^date, "a message"] = Common.to_list({participant, actor})
  end

  test "convert anonymous participants to list items" do
    participant = insert(:participant)
    actor = insert(:actor, domain: nil, preferred_username: "anonymous")
    date = datetime_to_string(participant.inserted_at)
    assert ["Anonymous participant", _, ^date, ""] = Common.to_list({participant, actor})
  end
end
