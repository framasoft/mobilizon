defmodule Mobilizon.ConversationsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Service.Workers
  alias Mobilizon.Storage.Page

  describe "comments" do
    @valid_attrs %{text: "some text"}
    @update_attrs %{text: "some updated text"}
    @invalid_attrs %{text: nil, url: nil}

    test "list_comments/0 returns all comments" do
      %Comment{id: comment_id} = insert(:comment)
      comment_ids = Conversations.list_comments() |> Enum.map(& &1.id)
      assert comment_ids == [comment_id]
    end

    test "get_comment!/1 returns the comment with given id" do
      %Comment{id: comment_id} = insert(:comment)
      comment_fetched = Conversations.get_comment!(comment_id)
      assert comment_fetched.id == comment_id
    end

    test "create_comment/1 with valid data creates a comment" do
      %Actor{} = actor = insert(:actor)
      comment_data = Map.merge(@valid_attrs, %{actor_id: actor.id})

      case Conversations.create_comment(comment_data) do
        {:ok, %Comment{} = comment} ->
          assert comment.text == "some text"
          assert comment.actor_id == actor.id

        err ->
          flunk("Failed to create a comment #{inspect(err)}")
      end
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      %Comment{} = comment = insert(:comment)

      case Conversations.update_comment(comment, @update_attrs) do
        {:ok, %Comment{} = comment} ->
          assert comment.text == "some updated text"

        err ->
          flunk("Failed to update a comment #{inspect(err)}")
      end
    end

    test "update_comment/2 with invalid data returns error changeset" do
      %Comment{} = comment = insert(:comment)
      assert {:error, %Ecto.Changeset{}} = Conversations.update_comment(comment, @invalid_attrs)
      %Comment{} = comment_fetched = Conversations.get_comment!(comment.id)
      assert comment = comment_fetched
    end

    test "delete_comment/1 deletes the comment" do
      %Comment{} = comment = insert(:comment)
      assert {:ok, %Comment{}} = Conversations.delete_comment(comment)
      refute is_nil(Conversations.get_comment!(comment.id).deleted_at)
    end
  end
end
