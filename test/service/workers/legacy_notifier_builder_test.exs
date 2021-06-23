defmodule Mobilizon.Service.Workers.LegacyNotifierBuilderTest do
  @moduledoc """
  Test the ActivityBuilder module
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Notifier.Mock, as: NotifierMock
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder
  alias Mobilizon.Users.{Setting, User}

  use Mobilizon.DataCase
  use Mobilizon.Tests.Helpers
  import Mox
  import Mobilizon.Factory

  setup_all do
    Mox.defmock(NotifierMock, for: Mobilizon.Service.Notifier)

    clear_config([Mobilizon.Service.Notifier, :notifiers], [
      NotifierMock
    ])

    :ok
  end

  @comment_mentionned %{
    "type" => "comment",
    "subject" => "event_comment_mention",
    "object_type" => "comment",
    "inserted_at" => DateTime.utc_now(),
    "op" => "legacy_notify"
  }

  @discussion_mentionned %{
    "type" => "discussion",
    "subject" => "discussion_mention",
    "object_type" => "discussion",
    "inserted_at" => DateTime.utc_now(),
    "op" => "legacy_notify"
  }

  @announcement %{
    "type" => "comment",
    "subject" => "participation_event_comment",
    "object_type" => "comment",
    "inserted_at" => DateTime.utc_now(),
    "op" => "legacy_notify"
  }

  setup :verify_on_exit!

  describe "Generates a comment mention notification " do
    test "not if the actor is remote" do
      %User{} = user1 = insert(:user)

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{id: actor_id_2} = insert(:actor, domain: "remote.tld", user: nil)

      %Event{title: title, uuid: uuid} = event = insert(:event)
      %Comment{id: comment_id} = insert(:comment, event: event, actor: actor)

      args =
        Map.merge(@comment_mentionned, %{
          "subject_params" => %{
            "event_uuid" => uuid,
            "event_title" => title
          },
          "author_id" => actor_id,
          "object_id" => to_string(comment_id),
          "mentions" => [actor_id_2]
        })

      NotifierMock
      |> expect(:ready?, 0, fn -> true end)
      |> expect(:send, 0, fn %User{},
                             %Activity{
                               type: :comment,
                               subject: :event_comment_mention,
                               object_type: :comment
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end

    test "if the actor mentionned is local" do
      %User{} = user1 = insert(:user)
      %User{} = user2 = insert(:user)
      %Setting{} = settings2 = insert(:settings, user: user2, user_id: user2.id)
      user2 = %User{user2 | settings: settings2}

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{id: actor_id_2} = insert(:actor, user: user2)

      %Event{title: title, uuid: uuid} = event = insert(:event)
      %Comment{id: comment_id} = insert(:comment, event: event, actor: actor)

      args =
        Map.merge(@comment_mentionned, %{
          "subject_params" => %{
            "event_uuid" => uuid,
            "event_title" => title
          },
          "author_id" => actor_id,
          "object_id" => to_string(comment_id),
          "mentions" => [actor_id_2]
        })

      NotifierMock
      |> expect(:ready?, fn -> true end)
      |> expect(:send, fn %User{},
                          %Activity{
                            type: :comment,
                            subject: :event_comment_mention,
                            object_type: :comment
                          },
                          [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end
  end

  describe "Generates an announcement comment notification" do
    test "not if there's no participants" do
      %User{} = user1 = insert(:user)

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{} = insert(:actor, domain: "remote.tld", user: nil)

      %Event{title: title, uuid: uuid, id: event_id} = event = insert(:event)
      %Comment{id: comment_id} = insert(:comment, event: event, actor: actor)

      args =
        Map.merge(@announcement, %{
          "subject_params" => %{
            "event_uuid" => uuid,
            "event_title" => title,
            "event_id" => event_id
          },
          "author_id" => actor_id,
          "object_id" => to_string(comment_id)
        })

      NotifierMock
      |> expect(:ready?, 0, fn -> true end)
      |> expect(:send, 0, fn %User{},
                             %Activity{
                               type: :comment,
                               subject: :participation_event_comment,
                               object_type: :comment
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end

    test "if there's some participants" do
      %User{} = user1 = insert(:user)
      %User{} = user2 = insert(:user)
      %Setting{} = settings2 = insert(:settings, user: user2, user_id: user2.id)
      user2 = %User{user2 | settings: settings2}

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{} = actor2 = insert(:actor, user: user2)

      %Event{title: title, uuid: uuid, id: event_id} = event = insert(:event)
      %Comment{id: comment_id} = insert(:comment, event: event, actor: actor)
      insert(:participant, event: event, actor: actor2)

      args =
        Map.merge(@announcement, %{
          "subject_params" => %{
            "event_uuid" => uuid,
            "event_title" => title,
            "event_id" => event_id
          },
          "author_id" => actor_id,
          "object_id" => to_string(comment_id)
        })

      NotifierMock
      |> expect(:ready?, fn -> true end)
      |> expect(:send, fn %User{},
                          %Activity{
                            type: :comment,
                            subject: :participation_event_comment,
                            object_type: :comment
                          },
                          [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end
  end

  describe "Generates a discussion mention notification " do
    test "not if the actor is remote" do
      %User{} = user1 = insert(:user)

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{id: actor_id_2} = insert(:actor, domain: "remote.tld", user: nil)

      %Comment{id: comment_id} = insert(:comment, actor: actor)

      %Discussion{
        actor_id: group_id,
        title: discussion_title,
        slug: discussion_slug
      } = insert(:discussion)

      args =
        Map.merge(@discussion_mentionned, %{
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "author_id" => actor_id,
          "group_id" => group_id,
          "object_id" => to_string(comment_id),
          "mentions" => [actor_id_2]
        })

      NotifierMock
      |> expect(:ready?, 0, fn -> true end)
      |> expect(:send, 0, fn %User{},
                             %Activity{
                               type: :discussion,
                               subject: :discussion_mention,
                               object_type: :discussion
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end

    test "not if the actor is not a member" do
      %User{} = user1 = insert(:user)

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{id: actor_id_2} = insert(:actor)

      %Comment{id: comment_id} = insert(:comment, actor: actor)

      %Discussion{
        actor_id: group_id,
        title: discussion_title,
        slug: discussion_slug
      } = insert(:discussion)

      args =
        Map.merge(@discussion_mentionned, %{
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "author_id" => actor_id,
          "group_id" => group_id,
          "object_id" => to_string(comment_id),
          "mentions" => [actor_id_2]
        })

      NotifierMock
      |> expect(:ready?, 0, fn -> true end)
      |> expect(:send, 0, fn %User{},
                             %Activity{
                               type: :discussion,
                               subject: :discussion_mention,
                               object_type: :discussion
                             },
                             [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end

    test "if the actor mentionned is local and a member" do
      %User{} = user1 = insert(:user)
      %User{} = user2 = insert(:user)
      %Setting{} = settings2 = insert(:settings, user: user2, user_id: user2.id)
      user2 = %User{user2 | settings: settings2}

      %Actor{id: actor_id} = actor = insert(:actor, user: user1)
      %Actor{id: actor_id_2} = actor2 = insert(:actor, user: user2)
      %Actor{} = group = insert(:group)

      insert(:member, actor: actor2, parent: group, role: :member)

      %Comment{id: comment_id} = insert(:comment, actor: actor)

      %Discussion{
        actor_id: group_id,
        title: discussion_title,
        slug: discussion_slug
      } = insert(:discussion, actor: group)

      args =
        Map.merge(@discussion_mentionned, %{
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "author_id" => actor_id,
          "group_id" => group_id,
          "object_id" => to_string(comment_id),
          "mentions" => [actor_id_2]
        })

      NotifierMock
      |> expect(:ready?, fn -> true end)
      |> expect(:send, fn %User{},
                          %Activity{
                            type: :discussion,
                            subject: :discussion_mention,
                            object_type: :discussion
                          },
                          [single_activity: true] ->
        {:ok, :sent}
      end)

      assert :ok == LegacyNotifierBuilder.perform(%Oban.Job{args: args})
    end
  end
end
