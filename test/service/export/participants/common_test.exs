defmodule Mobilizon.Service.Export.Participants.CommonTest do
  use Mobilizon.DataCase, async: true

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Export.Participants.Common

  test "convert participants to list items" do
    participant = insert(:participant)
    actor = insert(:actor)
    name = Actor.display_name_and_username(actor)
    assert [^name, _, ""] = Common.to_list({participant, actor})
  end

  test "convert participants with metadata to list items" do
    participant = insert(:participant, metadata: %{message: "a message"})
    actor = insert(:actor)
    name = Actor.display_name_and_username(actor)
    assert [^name, _, "a message"] = Common.to_list({participant, actor})
  end

  test "convert anonymous participants to list items" do
    participant = insert(:participant)
    actor = insert(:actor, domain: nil, preferred_username: "anonymous")
    assert ["Anonymous participant", _, ""] = Common.to_list({participant, actor})
  end
end
