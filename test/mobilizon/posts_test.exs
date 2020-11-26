defmodule Mobilizon.PostsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Posts
  alias Mobilizon.Posts.Post

  describe "posts" do
    @valid_attrs %{body: "some text", title: "some title"}
    @update_attrs %{body: "some updated text", title: "some updated title"}
    @invalid_attrs %{body: nil}

    test "list_posts/0 returns all posts" do
      group = insert(:group)
      %Post{id: post_id} = insert(:post, attributed_to: group)
      post_ids = Posts.get_posts_for_group(group).elements |> Enum.map(& &1.id)
      assert post_ids == [post_id]
    end

    test "get_post!/1 returns the post with given id" do
      %Post{id: post_id} = insert(:post)
      post_fetched = Posts.get_post(post_id)
      assert post_fetched.id == post_id
    end

    test "create_post/1 with valid data creates a post" do
      %Actor{} = actor = insert(:actor)
      %Actor{} = group = insert(:group)
      post_data = Map.merge(@valid_attrs, %{author_id: actor.id, attributed_to_id: group.id})

      case Posts.create_post(post_data) do
        {:ok, %Post{} = post} ->
          assert post.body == "some text"
          assert post.author_id == actor.id
          assert post.title == "some title"
          assert post.slug == "some-title-" <> ShortUUID.encode!(post.id)

        err ->
          flunk("Failed to create a post #{inspect(err)}")
      end
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      %Actor{} = actor = insert(:actor)
      %Actor{} = group = insert(:group)
      post_data = Map.merge(@valid_attrs, %{author_id: actor.id, attributed_to_id: group.id})

      {:ok, %Post{} = post} = Posts.create_post(post_data)

      case Posts.update_post(post, @update_attrs) do
        {:ok, %Post{} = updated_post} ->
          assert updated_post.body == @update_attrs.body
          assert updated_post.title == @update_attrs.title
          # Slug and URL don't change
          assert updated_post.slug == post.slug
          assert updated_post.url == post.url

        err ->
          flunk("Failed to update a post #{inspect(err)}")
      end
    end

    test "update_post/2 with invalid data returns error changeset" do
      %Post{} = post = insert(:post)
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      %Post{} = post_fetched = Posts.get_post(post.id)
      assert post.body == post_fetched.body
    end

    test "delete_post/1 deletes the post" do
      %Post{} = post = insert(:post)
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert is_nil(Posts.get_post(post.id))
    end
  end
end
