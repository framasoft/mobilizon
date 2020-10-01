defmodule Mobilizon.GraphQL.Resolvers.PostTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.AbsintheHelpers

  @post_fragment """
  fragment PostFragment on Post {
    id
    title
    slug
    url
    body
    author {
      id
      preferredUsername
      name
      avatar {
        url
      }
    }
    attributedTo {
      id
      preferredUsername
      name
      avatar {
        url
      }
    }
    visibility
    insertedAt
    updatedAt
    draft
  }
  """

  @get_group_posts """
  query($name: String!, $page: Int, $limit: Int) {
    group(preferredUsername: $name) {
        id
        posts(page: $page, limit: $limit) {
            elements {
                id,
                title,
            },
            total
        },
    }
  }
  """

  @post_query """
  query Post($slug: String!) {
    post(slug: $slug) {
        ...PostFragment
    }
  }
  #{@post_fragment}
  """

  @create_post """
  mutation CreatePost($title: String!, $body: String, $attributedToId: ID!, $draft: Boolean) {
    createPost(title: $title, body: $body, attributedToId: $attributedToId, draft: $draft) {
      ...PostFragment
    }
  }
  #{@post_fragment}
  """

  @update_post """
  mutation UpdatePost($id: ID!, $title: String, $body: String, $attributedToId: ID, $draft: Boolean) {
    updatePost(id: $id, title: $title, body: $body, attributedToId: $attributedToId, draft: $draft) {
      ...PostFragment
    }
  }
  #{@post_fragment}
  """

  @delete_post """
  mutation DeletePost($id: ID!) {
    deletePost(id: $id) {
        id
    }
  }
  """

  @post_title "my post"
  @updated_post_title "my updated post"

  setup do
    %User{} = user = insert(:user)
    %Actor{} = actor = insert(:actor, user: user)
    %Actor{} = group = insert(:group)
    %Post{} = post = insert(:post, attributed_to: group, author: actor)

    %Post{} =
      post_unlisted = insert(:post, attributed_to: group, author: actor, visibility: :unlisted)

    %Post{} = post_draft = insert(:post, attributed_to: group, author: actor, draft: true)
    %Member{} = insert(:member, parent: group, actor: actor, role: :member)

    %Post{} =
      post_private = insert(:post, attributed_to: group, author: actor, visibility: :private)

    {:ok,
     user: user,
     group: group,
     post: post,
     post_unlisted: post_unlisted,
     post_draft: post_draft,
     post_private: post_private}
  end

  describe "Resolver: Get group's posts" do
    test "find_posts_for_group/3", %{
      conn: conn,
      user: user,
      group: group,
      post: post,
      post_unlisted: post_unlisted,
      post_draft: post_draft,
      post_private: post_private
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_group_posts,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["posts"]["total"] == 4

      assert res["data"]["group"]["posts"]["elements"] |> Enum.map(& &1["id"]) |> MapSet.new() ==
               MapSet.new([
                 post.id,
                 post_unlisted.id,
                 post_draft.id,
                 post_private.id
               ])
    end

    test "find_posts_for_group/3 when not member of group", %{
      conn: conn,
      group: group,
      post: post
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_group_posts,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["posts"]["total"] == 1

      assert res["data"]["group"]["posts"]["elements"] |> Enum.map(& &1["id"]) == [post.id]
    end

    test "find_posts_for_group/3 when not connected", %{
      conn: conn,
      group: group,
      post: post
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @get_group_posts,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["posts"]["total"] == 1

      assert res["data"]["group"]["posts"]["elements"] |> Enum.map(& &1["id"]) == [post.id]
    end
  end

  describe "Resolver: Get a specific post" do
    test "get_post/3 for a public post", %{
      conn: conn,
      user: user,
      post: post
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post.title
    end

    test "get_post/3 for a non-existing post", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: "not existing"
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end

    test "get_post/3 for an unlisted post", %{
      conn: conn,
      user: user,
      post_unlisted: post_unlisted
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_unlisted.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post_unlisted.title

      assert res["data"]["post"]["visibility"] ==
               post_unlisted.visibility |> to_string() |> String.upcase()
    end

    test "get_post/3 for a private post", %{
      conn: conn,
      user: user,
      post_private: post_private
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_private.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post_private.title

      assert res["data"]["post"]["visibility"] ==
               post_private.visibility |> to_string() |> String.upcase()
    end

    test "get_post/3 for a draft post", %{
      conn: conn,
      user: user,
      post_draft: post_draft
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_draft.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post_draft.title
      assert res["data"]["post"]["draft"] == true
    end

    test "get_post/3 without being a member for a public post", %{
      conn: conn,
      post: post
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post.title
    end

    test "get_post/3 without being connected for a public post", %{
      conn: conn,
      post: post
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post.title
    end

    test "get_post/3 without being a member for an unlisted post", %{
      conn: conn,
      post_unlisted: post_unlisted
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_unlisted.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post_unlisted.title

      assert res["data"]["post"]["visibility"] ==
               post_unlisted.visibility |> to_string() |> String.upcase()
    end

    test "get_post/3 without being a member for a private post", %{
      conn: conn,
      post_private: post_private
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_private.slug
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end

    test "get_post/3 without being connected for an unlisted post still gives the post", %{
      conn: conn,
      post_unlisted: post_unlisted
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_unlisted.slug
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["post"]["title"] == post_unlisted.title

      assert res["data"]["post"]["visibility"] ==
               post_unlisted.visibility |> to_string() |> String.upcase()
    end

    test "get_post/3 without being connected for a private post", %{
      conn: conn,
      post_private: post_private
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_private.slug
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end

    test "get_post/3 without being a member for a draft post", %{
      conn: conn,
      post_draft: post_draft
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_draft.slug
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end

    test "get_post/3 without being connected for a draft post", %{
      conn: conn,
      post_draft: post_draft
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_draft.slug
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end
  end

  describe "Resolver: Create a post" do
    test "create_post/3 creates a post for a group", %{
      conn: conn,
      user: user,
      group: group
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_post,
          variables: %{
            title: @post_title,
            body: "My new post is here",
            attributedToId: group.id
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["createPost"]["title"] == @post_title
      id = res["data"]["createPost"]["id"]
      assert res["data"]["createPost"]["slug"] == "my-post-#{ShortUUID.encode!(id)}"
    end

    test "create_post/3 doesn't create a post if no group is defined", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_post,
          variables: %{
            title: @post_title,
            body: "some body",
            attributedToId: nil
          }
        )

      assert Enum.map(res["errors"], & &1["message"]) == [
               "Argument \"attributedToId\" has invalid value $attributedToId.",
               "Variable \"attributedToId\": Expected non-null, found null."
             ]
    end

    test "create_post/3 doesn't create a post if the actor is not a member of the group",
         %{
           conn: conn,
           group: group
         } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_post,
          variables: %{
            title: @post_title,
            body: "My body",
            attributedToId: group.id
          }
        )

      assert Enum.map(res["errors"], & &1["message"]) == [
               "Profile is not member of group"
             ]
    end
  end

  describe "Resolver: Update a post" do
    test "update_post/3 updates a post for a group", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Post{id: post_id} = insert(:post, attributed_to: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_post,
          variables: %{
            id: post_id,
            title: @updated_post_title
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updatePost"]["title"] == @updated_post_title
    end
  end

  describe "Resolver: Delete a post" do
    test "delete_post/3 deletes a post", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Post{id: post_id, slug: post_slug} =
        insert(:post,
          attributed_to: group
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_post,
          variables: %{
            id: post_id
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["deletePost"]["id"] == post_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @post_query,
          variables: %{
            slug: post_slug
          }
        )

      assert hd(res["errors"])["message"] == "Post not found"
    end

    test "delete_post/3 deletes a post not found", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_post,
          variables: %{
            id: "not found"
          }
        )

      assert hd(res["errors"])["message"] == "Post ID is not a valid ID"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_post,
          variables: %{
            id: "d276ef98-8433-48d7-890e-c24eda0dcdbe"
          }
        )

      assert hd(res["errors"])["message"] == "Post doesn't exist"
    end
  end
end
