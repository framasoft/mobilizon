defmodule Mobilizon.Federation.ActivityPub.AudienceTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Mention
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Repo

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  describe "get audience for an event created from a profile" do
    test "when the event is public" do
      %Event{} = event = insert(:event)
      event = Repo.preload(event, [:comments])

      assert %{"cc" => [event.organizer_actor.followers_url], "to" => [@ap_public]} ==
               Audience.get_audience(event)
    end

    test "when the event is unlisted" do
      %Event{} = event = insert(:event, visibility: :unlisted)
      event = Repo.preload(event, [:comments])

      assert %{"cc" => [@ap_public], "to" => [event.organizer_actor.followers_url]} ==
               Audience.get_audience(event)
    end

    test "when the event is unlisted and mentions some actors" do
      %Actor{id: mentionned_actor_id, url: mentionned_actor_url} =
        insert(:actor, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Event{} = event = insert(:event, visibility: :unlisted)
      event = Repo.preload(event, [:comments])
      mentions = [%Mention{actor_id: mentionned_actor_id}]
      event = %Event{event | mentions: mentions}

      assert %{
               "cc" => [@ap_public],
               "to" => [event.organizer_actor.followers_url, mentionned_actor_url]
             } ==
               Audience.get_audience(event)
    end

    test "with interactions" do
      %Actor{} = interactor = insert(:actor)

      %Event{} = event = insert(:event)

      insert(:share, owner_actor: event.organizer_actor, actor: interactor, uri: event.url)

      event = Repo.preload(event, [:comments])

      assert %{
               "cc" => [event.organizer_actor.followers_url, interactor.url],
               "to" => [@ap_public]
             } ==
               Audience.get_audience(event)
    end
  end

  describe "get audience for an event created from a group member" do
    test "when the event is public" do
      %Actor{} = actor = insert(:actor)

      %Actor{
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Event{} = event = insert(:event, attributed_to: group, organizer_actor: actor)
      event = Repo.preload(event, [:comments])

      assert %{
               "cc" => [members_url, followers_url],
               "to" => [@ap_public]
             } ==
               Audience.get_audience(event)
    end

    test "when the event is unlisted" do
      %Actor{} = actor = insert(:actor)

      %Actor{
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Event{} =
        event =
        insert(:event, visibility: :unlisted, attributed_to: group, organizer_actor: actor)

      event = Repo.preload(event, [:comments])

      assert %{
               "cc" => [@ap_public],
               "to" => [members_url, followers_url]
             } ==
               Audience.get_audience(event)
    end

    test "when the event is unlisted and mentions some actors" do
      %Actor{id: mentionned_actor_id, url: mentionned_actor_url} =
        insert(:actor, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Actor{} = actor = insert(:actor)

      %Actor{
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@a_group")

      %Event{} =
        event =
        insert(:event, visibility: :unlisted, attributed_to: group, organizer_actor: actor)

      event = Repo.preload(event, [:comments])
      mentions = [%Mention{actor_id: mentionned_actor_id}]
      event = %Event{event | mentions: mentions}

      assert %{
               "cc" => [@ap_public],
               "to" => [members_url, followers_url, mentionned_actor_url]
             } ==
               Audience.get_audience(event)
    end
  end

  describe "get audience for a post" do
    test "when it's public" do
      %Actor{
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Post{} = post = insert(:post, attributed_to: group)

      assert %{"to" => [@ap_public], "cc" => [members_url, followers_url]} ==
               Audience.get_audience(post)
    end

    test "when it's unlisted" do
      %Actor{
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Post{} = post = insert(:post, attributed_to: group, visibility: :unlisted)

      assert %{"to" => [members_url, followers_url], "cc" => [@ap_public]} ==
               Audience.get_audience(post)
    end

    test "when it's private" do
      %Actor{
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Post{} = post = insert(:post, attributed_to: group, visibility: :private)

      assert %{"to" => [members_url], "cc" => []} ==
               Audience.get_audience(post)
    end

    test "when it's still a draft" do
      %Actor{
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Post{} = post = insert(:post, attributed_to: group, draft: true)

      assert %{"to" => [members_url], "cc" => []} ==
               Audience.get_audience(post)
    end
  end

  describe "get audience for a discussion" do
    test "basic" do
      %Actor{
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Discussion{} = discussion = insert(:discussion, actor: group)

      assert %{"to" => [members_url], "cc" => []} ==
               Audience.get_audience(discussion)
    end
  end

  describe "get audience for a comment" do
    test "basic" do
      %Actor{id: mentionned_actor_id, url: mentionned_actor_url} =
        insert(:actor, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Comment{} = comment = insert(:comment)
      mentions = [%Mention{actor_id: mentionned_actor_id}]
      comment = %Comment{comment | mentions: mentions}

      assert %{
               "cc" => [comment.actor.followers_url],
               "to" => [@ap_public, mentionned_actor_url, comment.event.organizer_actor.url]
             } ==
               Audience.get_audience(comment)
    end

    test "in reply to other comments" do
      %Actor{id: mentionned_actor_id, url: mentionned_actor_url} =
        insert(:actor, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Comment{} = original_comment = insert(:comment)

      %Comment{} =
        reply_comment =
        insert(:comment, in_reply_to_comment: original_comment, origin_comment: original_comment)

      %Comment{} =
        comment =
        insert(:comment, in_reply_to_comment: reply_comment, origin_comment: original_comment)

      mentions = [%Mention{actor_id: mentionned_actor_id}]
      comment = %Comment{comment | mentions: mentions}

      assert %{
               "cc" => [comment.actor.followers_url, original_comment.actor.url],
               "to" => [
                 @ap_public,
                 mentionned_actor_url,
                 reply_comment.actor.url,
                 comment.event.organizer_actor.url
               ]
             } ==
               Audience.get_audience(comment)
    end

    test "part of a discussion" do
      %Actor{
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Discussion{} = discussion = insert(:discussion, actor: group)
      %Comment{} = comment = insert(:comment, discussion: discussion)

      assert %{"to" => [members_url], "cc" => []} ==
               Audience.get_audience(comment)
    end
  end

  describe "participant" do
    test "basic" do
      %Event{} = event = insert(:event)
      %Participant{} = participant2 = insert(:participant, event: event)
      %Participant{} = participant = insert(:participant, event: event)

      assert %{
               "to" => [participant.actor.url, participant.event.organizer_actor.url],
               "cc" => [participant2.actor.url, participant.actor.url]
             } == Audience.get_audience(participant)
    end

    test "to a group event" do
      %Actor{} =
        group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      %Event{} = event = insert(:event, attributed_to: group)
      %Participant{} = participant2 = insert(:participant, event: event)
      %Participant{} = participant = insert(:participant, event: event)

      assert %{
               "to" => [participant.actor.url, participant.event.attributed_to.url],
               "cc" => [participant2.actor.url, participant.actor.url]
             } == Audience.get_audience(participant)
    end
  end

  describe "member" do
    test "basic" do
      %Member{} = member = insert(:member)

      assert %{"to" => [member.parent.url, member.parent.members_url], "cc" => []} ==
               Audience.get_audience(member)
    end
  end

  describe "actor" do
    test "basic" do
      %Actor{followers_url: followers_url} = actor = insert(:actor)

      assert %{"to" => [@ap_public], "cc" => [followers_url]} ==
               Audience.get_audience(actor)
    end

    test "group" do
      %Actor{followers_url: followers_url, members_url: members_url, type: :Group} =
        group = insert(:group)

      assert %{"to" => [@ap_public], "cc" => [members_url, followers_url]} ==
               Audience.get_audience(group)
    end

    test "with interactions" do
      %Actor{followers_url: followers_url, members_url: members_url, type: :Group} =
        group = insert(:group)

      %Actor{} = interactor = insert(:actor)

      insert(:share, owner_actor: group, actor: interactor)

      assert %{
               "to" => [@ap_public],
               "cc" => [members_url, followers_url, interactor.url]
             } ==
               Audience.get_audience(group)
    end
  end
end
