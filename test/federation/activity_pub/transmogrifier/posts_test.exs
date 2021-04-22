defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.PostsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Posts.Post

  describe "handle incoming posts" do
    setup :verify_on_exit!

    test "it ignores an incoming post if we already have it" do
      post = insert(:post)
      post = Repo.preload(post, [:author, :attributed_to, :picture, :media])

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => post.author.url,
        "attributedTo" => post.attributed_to.url,
        "object" => Convertible.model_to_as(post)
      }

      data =
        File.read!("test/fixtures/mobilizon-post-activity-group.json")
        |> Jason.decode!()
        |> Map.merge(activity)

      assert {:ok, nil, _} = Transmogrifier.handle_incoming(data)
    end

    test "it receives a draft post correctly as a member" do
      %Actor{} = group = insert(:group, domain: "remote.tld", url: "https://remote.tld/@group")
      %Actor{} = author = insert(:actor, domain: "remote.tld", url: "https://remote.tld/@author")
      insert(:member, parent: group, actor: author, role: :moderator)
      insert(:member, parent: group, role: :member)

      object =
        Convertible.model_to_as(%Post{
          url: "https://remote.tld/@group/some-slug",
          author: author,
          attributed_to: group,
          picture: nil,
          media: [],
          body: "my body",
          title: "my title",
          draft: true
        })

      data =
        File.read!("test/fixtures/mobilizon-post-activity-group.json")
        |> Jason.decode!()
        |> Map.put("object", object)

      assert {:ok, %Activity{}, %Post{draft: true}} = Transmogrifier.handle_incoming(data)
    end

    test "it publishes a previously draft post correctly as a member" do
      %Actor{} = group = insert(:group, domain: "remote.tld", url: "https://remote.tld/@group")
      %Actor{} = author = insert(:actor, domain: "remote.tld", url: "https://remote.tld/@author")
      insert(:member, parent: group, actor: author, role: :moderator)
      insert(:member, parent: group, role: :member)

      %Post{} =
        post =
        insert(:post,
          url: "https://remote.tld/@group/some-slug",
          author: author,
          attributed_to: group,
          draft: true
        )

      activity = %{
        "type" => "Update",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => post.author.url,
        "attributedTo" => post.attributed_to.url,
        "object" => Convertible.model_to_as(%Post{post | draft: false})
      }

      data =
        File.read!("test/fixtures/mobilizon-post-activity-group.json")
        |> Jason.decode!()
        |> Map.merge(activity)

      assert {:ok, %Activity{}, %Post{draft: false}} = Transmogrifier.handle_incoming(data)
    end
  end
end
