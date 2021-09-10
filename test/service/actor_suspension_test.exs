defmodule Mobilizon.Service.ActorSuspensionTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Actors, Config, Discussions, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.ActorSuspension
  alias Mobilizon.Web.Upload.Uploader

  describe "suspend a person" do
    setup do
      user = insert(:user)
      %Actor{} = actor = insert(:actor, user: user)
      insert(:actor, user: user)

      %Comment{} = comment = insert(:comment, actor: actor)
      %Event{} = event = insert(:event, organizer_actor: actor)
      %Event{} = insert(:event)
      insert(:participant, event: event)

      %Participant{} =
        participant = insert(:participant, actor: actor, event: event, role: :participant)

      {:ok, actor: actor, comment: comment, event: event, participant: participant}
    end

    test "local", %{actor: actor, comment: comment, event: event, participant: participant} do
      assert actor
             |> media_paths()
             |> media_exists?()

      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(actor)
      assert %Actor{suspended: true} = Actors.get_actor(actor.id)
      assert %Comment{deleted_at: %DateTime{}} = Discussions.get_comment(comment.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)
      assert nil == Events.get_participant(participant.id)

      refute actor
             |> media_paths()
             |> media_exists?()
    end
  end

  describe "delete a person" do
    setup do
      %Actor{} = actor = insert(:actor)

      %Comment{} = comment = insert(:comment, actor: actor)
      %Event{} = event = insert(:event, organizer_actor: actor)

      {:ok, actor: actor, comment: comment, event: event}
    end

    test "local", %{actor: actor, comment: comment, event: event} do
      assert actor
             |> media_paths()
             |> media_exists?()

      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(actor, reserve_username: false)
      assert nil == Actors.get_actor(actor.id)
      assert %Comment{deleted_at: %DateTime{}} = Discussions.get_comment(comment.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)

      refute actor
             |> media_paths()
             |> media_exists?()
    end
  end

  describe "suspend a group" do
    setup do
      %Actor{} = group = insert(:group)

      %Event{} = event = insert(:event, attributed_to: group)

      {:ok, group: group, event: event}
    end

    test "local", %{group: group, event: event} do
      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(group)
      assert %Actor{suspended: true} = Actors.get_actor(group.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)
    end
  end

  defp media_paths(%Actor{avatar: %{url: avatar_url}, banner: %{url: banner_url}}) do
    %URI{path: "/media/" <> avatar_path} = URI.parse(avatar_url)
    %URI{path: "/media/" <> banner_path} = URI.parse(banner_url)
    %{avatar: avatar_path, banner: banner_path}
  end

  defp media_exists?(%{avatar: avatar_path, banner: banner_path}) do
    File.exists?(
      Config.get!([Uploader.Local, :uploads]) <>
        "/" <> avatar_path
    ) &&
      File.exists?(
        Config.get!([Uploader.Local, :uploads]) <>
          "/" <> banner_path
      )
  end
end
