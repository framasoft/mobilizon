defmodule Mobilizon.Federation.ActivityPub.Types.ActorsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.Actors

  describe "group creation" do
    test "with no public key" do
      %Actor{id: creator_actor_id} = insert(:actor)

      assert_raise RuntimeError, "No publickey found in private keys", fn ->
        Actors.create(
          %{
            preferred_username: "hello",
            summary: "hi",
            url: "https://some-unique-url.test/@actor",
            keys: "yool",
            creator_actor_id: creator_actor_id
          },
          %{}
        )
      end
    end

    test "with XSS" do
      %Actor{id: creator_actor_id} = insert(:actor)

      preferred_username =
        "hello <meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"

      summary =
        "<p>Some text before <meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" /></p>"

      assert {:ok, %Actor{preferred_username: saved_preferred_username, summary: saved_summary},
              _} =
               Actors.create(
                 %{
                   preferred_username: preferred_username,
                   summary: summary,
                   url: "https://some-unique-url.test/@actor",
                   creator_actor_id: creator_actor_id,
                   type: :Group
                 },
                 %{}
               )

      assert saved_preferred_username == "hello"
      assert saved_summary == "<p>Some text before </p>"

      preferred_username =
        "<<img src=''/>meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"

      summary =
        "<<img src=''/>meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Actors.create(
                 %{
                   preferred_username: preferred_username,
                   summary: summary,
                   url: "https://some-unique-url.test/@actor",
                   creator_actor_id: creator_actor_id,
                   type: :Group
                 },
                 %{}
               )

      assert errors === [
               preferred_username:
                 {"Username must only contain alphanumeric lowercased characters and underscores.",
                  []}
             ]

      assert {:ok, %Actor{summary: saved_summary}, _} =
               Actors.create(
                 %{
                   preferred_username: "hello184",
                   summary: summary,
                   url: "https://some-unique-url.test/@actor",
                   creator_actor_id: creator_actor_id,
                   type: :Group
                 },
                 %{}
               )

      assert saved_summary ==
               "&lt;<img src=\"\"/>meta http-equiv=&quot;refresh&quot; content=&quot;0; url=http://example.com/&quot; /&gt;"
    end
  end
end
