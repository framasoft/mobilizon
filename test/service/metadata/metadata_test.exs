defmodule Mobilizon.Service.MetadataTest do
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Metadata
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes
  use Mobilizon.DataCase
  import Mobilizon.Factory

  describe "build_tags/2 for an actor" do
    test "that is a group gives tags" do
      %Actor{} = group = insert(:group, name: "My group")

      assert group |> Metadata.build_tags() |> Metadata.Utils.stringify_tags() ==
               "<meta content=\"#{group.name} (@#{group.preferred_username})\" property=\"og:title\"><meta content=\"#{
                 group.url
               }\" property=\"og:url\"><meta content=\"The event organizer didn&#39;t add any description.\" property=\"og:description\"><meta content=\"profile\" property=\"og:type\"><meta content=\"#{
                 group.preferred_username
               }\" property=\"profile:username\"><meta content=\"summary\" property=\"twitter:card\"><meta content=\"#{
                 group.avatar.url
               }\" property=\"og:image\"><script type=\"application/ld+json\">{\"@context\":\"http://schema.org\",\"@type\":\"Organization\",\"address\":null,\"name\":\"#{
                 group.name
               }\",\"url\":\"#{group.url}\"}</script><link href=\"#{
                 Routes.feed_url(Endpoint, :actor, group.preferred_username, "atom")
               }\" rel=\"alternate\" title=\"#{group.name}'s feed\" type=\"application/atom+xml\"><link href=\"#{
                 Routes.feed_url(Endpoint, :actor, group.preferred_username, "ics")
               }\" rel=\"alternate\" title=\"#{group.name}'s feed\" type=\"text/calendar\">"

      assert group
             |> Map.put(:avatar, nil)
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               "<meta content=\"#{group.name} (@#{group.preferred_username})\" property=\"og:title\"><meta content=\"#{
                 group.url
               }\" property=\"og:url\"><meta content=\"The event organizer didn&#39;t add any description.\" property=\"og:description\"><meta content=\"profile\" property=\"og:type\"><meta content=\"#{
                 group.preferred_username
               }\" property=\"profile:username\"><meta content=\"summary\" property=\"twitter:card\"><script type=\"application/ld+json\">{\"@context\":\"http://schema.org\",\"@type\":\"Organization\",\"address\":null,\"name\":\"#{
                 group.name
               }\",\"url\":\"#{group.url}\"}</script><link href=\"#{
                 Routes.feed_url(Endpoint, :actor, group.preferred_username, "atom")
               }\" rel=\"alternate\" title=\"#{group.name}'s feed\" type=\"application/atom+xml\"><link href=\"#{
                 Routes.feed_url(Endpoint, :actor, group.preferred_username, "ics")
               }\" rel=\"alternate\" title=\"#{group.name}'s feed\" type=\"text/calendar\">"
    end

    test "that is not a group doesn't give anything" do
      %Actor{} = person = insert(:actor)

      assert person |> Metadata.build_tags() |> Metadata.Utils.stringify_tags() == ""
      assert person |> Metadata.build_tags("fr") |> Metadata.Utils.stringify_tags() == ""
    end
  end

  describe "build_tags/2 for an event" do
    test "gives tags" do
      alias Mobilizon.Web.Endpoint

      %Event{} = event = insert(:event)

      # Because the description in Schema.org data is double-escaped
      a = "\n"
      b = "\\n"

      assert event
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               "<title>#{event.title} - Mobilizon</title><meta content=\"#{event.description}\" name=\"description\"><meta content=\"#{
                 event.title
               }\" property=\"og:title\"><meta content=\"#{event.url}\" property=\"og:url\"><meta content=\"#{
                 event.description
               }\" property=\"og:description\"><meta content=\"website\" property=\"og:type\"><link href=\"#{
                 event.url
               }\" rel=\"canonical\"><meta content=\"#{event.picture.file.url}\" property=\"og:image\"><meta content=\"summary_large_image\" property=\"twitter:card\"><script type=\"application/ld+json\">{\"@context\":\"https://schema.org\",\"@type\":\"Event\",\"description\":\"#{
                 String.replace(event.description, a, b)
               }\",\"endDate\":\"#{DateTime.to_iso8601(event.ends_on)}\",\"eventStatus\":\"https://schema.org/EventScheduled\",\"image\":[\"#{
                 event.picture.file.url
               }\"],\"location\":{\"@type\":\"Place\",\"address\":{\"@type\":\"PostalAddress\",\"addressCountry\":\"My Country\",\"addressLocality\":\"My Locality\",\"addressRegion\":\"My Region\",\"postalCode\":\"My Postal Code\",\"streetAddress\":\"My Street Address\"},\"name\":\"#{
                 event.physical_address.description
               }\"},\"name\":\"#{event.title}\",\"organizer\":{\"@type\":\"Person\",\"name\":\"#{
                 event.organizer_actor.preferred_username
               }\"},\"performer\":{\"@type\":\"Person\",\"name\":\"#{
                 event.organizer_actor.preferred_username
               }\"},\"startDate\":\"#{DateTime.to_iso8601(event.begins_on)}\"}</script>"

      assert event
             |> Map.put(:picture, nil)
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               "<title>#{event.title} - Mobilizon</title><meta content=\"#{event.description}\" name=\"description\"><meta content=\"#{
                 event.title
               }\" property=\"og:title\"><meta content=\"#{event.url}\" property=\"og:url\"><meta content=\"#{
                 event.description
               }\" property=\"og:description\"><meta content=\"website\" property=\"og:type\"><link href=\"#{
                 event.url
               }\" rel=\"canonical\"><meta content=\"summary_large_image\" property=\"twitter:card\"><script type=\"application/ld+json\">{\"@context\":\"https://schema.org\",\"@type\":\"Event\",\"description\":\"#{
                 String.replace(event.description, a, b)
               }\",\"endDate\":\"#{DateTime.to_iso8601(event.ends_on)}\",\"eventStatus\":\"https://schema.org/EventScheduled\",\"image\":[\"#{
                 "#{Endpoint.url()}/img/mobilizon_default_card.png"
               }\"],\"location\":{\"@type\":\"Place\",\"address\":{\"@type\":\"PostalAddress\",\"addressCountry\":\"My Country\",\"addressLocality\":\"My Locality\",\"addressRegion\":\"My Region\",\"postalCode\":\"My Postal Code\",\"streetAddress\":\"My Street Address\"},\"name\":\"#{
                 event.physical_address.description
               }\"},\"name\":\"#{event.title}\",\"organizer\":{\"@type\":\"Person\",\"name\":\"#{
                 event.organizer_actor.preferred_username
               }\"},\"performer\":{\"@type\":\"Person\",\"name\":\"#{
                 event.organizer_actor.preferred_username
               }\"},\"startDate\":\"#{DateTime.to_iso8601(event.begins_on)}\"}</script>"
    end
  end

  describe "build_tags/2 for a post" do
    test "gives tags" do
      %Post{} = post = insert(:post)

      assert post
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               "<meta content=\"#{post.title}\" property=\"og:title\"><meta content=\"#{post.url}\" property=\"og:url\"><meta content=\"#{
                 Metadata.Utils.process_description(post.body)
               }\" property=\"og:description\"><meta content=\"article\" property=\"og:type\"><meta content=\"summary\" property=\"twitter:card\"><link href=\"#{
                 post.url
               }\" rel=\"canonical\"><meta content=\"summary_large_image\" property=\"twitter:card\"><script type=\"application/ld+json\">{\"@context\":\"https://schema.org\",\"@type\":\"Article\",\"author\":{\"@type\":\"Organization\",\"name\":\"#{
                 post.attributed_to.preferred_username
               }\"},\"dateModified\":\"#{DateTime.to_iso8601(post.updated_at)}\",\"datePublished\":\"#{
                 DateTime.to_iso8601(post.publish_at)
               }\",\"name\":\"My Awesome article\"}</script>"
    end
  end

  describe "build_tags/2 for a comment" do
    test "gives tags" do
      %Comment{} = comment = insert(:comment)

      assert comment
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               "<meta content=\"#{comment.actor.preferred_username}\" property=\"og:title\"><meta content=\"#{
                 comment.url
               }\" property=\"og:url\"><meta content=\"#{comment.text}\" property=\"og:description\"><meta content=\"website\" property=\"og:type\"><meta content=\"summary\" property=\"twitter:card\">"
    end
  end

  describe "build_tags/2 for a tombstone" do
    test "gives nothing" do
      %Tombstone{} = tombstone = insert(:tombstone)

      assert tombstone
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() == ""
    end
  end
end
