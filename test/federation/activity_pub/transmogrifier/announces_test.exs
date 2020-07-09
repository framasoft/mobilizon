defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.AnnouncesTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub.Transmogrifier
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.HTTP.ActivityPub.Mock
  alias Mobilizon.Tombstone

  @comment_text "my comment"

  describe "incoming announces for discussion creation" do
    setup :verify_on_exit!

    test "by group member works" do
      actor = insert(:actor)
      group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :member)

      %Comment{url: comment_url} =
        comment = build(:comment, actor: actor, attributed_to: group, event: nil)

      comment_data = Convertible.model_to_as(comment)

      Mock
      |> expect(:call, fn
        %{method: :get, url: ^comment_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: comment_data}}
      end)

      data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("actor", group.url)
        |> Map.put("object", comment.url)

      {:ok, _, %Comment{actor: %Actor{url: actor_url}, url: comment_url}} =
        Transmogrifier.handle_incoming(data)

      assert actor_url == comment.actor.url

      assert comment_url == comment.url
    end
  end

  describe "handle incoming announces for discussion updates" do
    setup :verify_on_exit!

    @updated_title "Updated title"

    test "by group member works" do
      actor =
        insert(:actor,
          domain: "otherremoteinstance.tld",
          url: "http://otherremoteinstance.tld/@somemember"
        )

      group =
        insert(:group,
          url: "http://remoteinstance.tld/@mygroup",
          domain: "remoteinstance.tld",
          members_url: "http://remoteinstance.tld/@mygroup/members"
        )

      insert(:member, parent: group, actor: actor, role: :member)

      %Comment{url: _comment_url} =
        comment =
        insert(:comment,
          actor: actor,
          attributed_to: group,
          text: @comment_text,
          url: "http://otherremoteinstance.tld/@somemember/uuid"
        )

      %Discussion{url: discussion_url} =
        discussion =
        insert(:discussion,
          last_comment: comment,
          comments: [comment],
          creator: actor,
          actor: group,
          url: "http://otherremoteinstance.tld/@mygroup/c/talk-of-something-sh0rt-uu1d"
        )

      discussion_updated = Map.put(discussion, :title, @updated_title)

      discussion_updated_data = Convertible.model_to_as(discussion_updated)

      Mock
      |> expect(:call, fn
        %{url: ^discussion_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: discussion_updated_data}}
      end)

      data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("actor", group.url)
        |> Map.put("object", discussion_url)

      assert {:ok, _, %Discussion{title: title}} = Transmogrifier.handle_incoming(data)
      assert title == @updated_title
    end
  end

  describe "handle incoming announces for discussion deletion" do
    setup :verify_on_exit!

    test "by group member works" do
      actor =
        insert(:actor,
          url: "http://otherremoteinstance.tld/@somemember",
          domain: "otherremoteinstance.tld"
        )

      group =
        insert(:group,
          url: "http://remoteinstance.tld/@mygroup",
          domain: "remoteinstance.tld",
          members_url: "http://remoteinstance.tld/@mygroup/members"
        )

      insert(:member, parent: group, actor: actor, role: :member)

      %Comment{url: comment_url} =
        comment =
        insert(:comment,
          actor: actor,
          attributed_to: group,
          text: @comment_text,
          url: "http://otherremoteinstance.tld/comment/uuid"
        )

      tombstone = build(:tombstone, uri: comment.url, actor: actor)
      tombstone_data = Convertible.model_to_as(tombstone)

      Mock
      |> expect(:call, fn
        %{url: ^comment_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: tombstone_data}}
      end)

      data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("actor", group.url)
        |> Map.put("object", comment.url)

      %Comment{deleted_at: deleted_at, text: comment_text} =
        Discussions.get_comment_from_url(comment.url)

      assert is_nil(deleted_at)
      assert comment_text == @comment_text

      {:ok, _, %Comment{deleted_at: deleted_at, text: comment_text}} =
        Transmogrifier.handle_incoming(data)

      refute is_nil(deleted_at)
      refute comment_text == @comment_text

      %Tombstone{actor_id: _actor_id, uri: tombstone_uri} = Tombstone.find_tombstone(comment_url)

      # assert actor_id == comment.actor.id

      assert tombstone_uri == comment.url
    end
  end
end
