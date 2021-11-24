defmodule Mobilizon.Federation.ActivityPub.UtilsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.Converter

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  describe "make" do
    test "comment data from struct" do
      comment = insert(:comment)
      tag = insert(:tag, title: "MyTag")
      reply = insert(:comment, in_reply_to_comment: comment, tags: [tag], attributed_to: nil)

      assert %{
               "type" => "Note",
               "to" => ["https://www.w3.org/ns/activitystreams#Public"],
               "cc" => [],
               "tag" => [
                 %{
                   "href" => "http://mobilizon.test/tags/#{tag.slug}",
                   "name" => "#MyTag",
                   "type" => "Hashtag"
                 }
               ],
               "content" => "My Comment",
               "actor" => reply.actor.url,
               "uuid" => reply.uuid,
               "id" => Routes.page_url(Endpoint, :comment, reply.uuid),
               "inReplyTo" => comment.url,
               "attributedTo" => reply.actor.url,
               "mediaType" => "text/html",
               "published" => reply.published_at |> DateTime.to_iso8601(),
               "isAnnouncement" => false
             } == Converter.Comment.model_to_as(reply)
    end

    test "comment data from map" do
      comment = insert(:comment, attributed_to: nil)
      reply = insert(:comment, in_reply_to_comment: comment, attributed_to: nil)
      to = ["https://www.w3.org/ns/activitystreams#Public"]
      comment_data = Converter.Comment.model_to_as(reply)
      assert comment_data["type"] == "Note"
      assert comment_data["to"] == to
      assert comment_data["content"] == reply.text
      assert comment_data["actor"] == reply.actor.url
      assert comment_data["inReplyTo"] == comment.url
    end
  end

  describe "origin_check?" do
    test "origin_check? with a tombstone" do
      assert Utils.origin_check?("http://an_uri", %{
               "type" => "Tombstone",
               "id" => "http://an_uri"
             })
    end
  end

  describe "get_actor/1" do
    test "with a string" do
      assert Utils.get_actor(%{"actor" => "https://somewhere.tld/@someone"}) ==
               "https://somewhere.tld/@someone"
    end

    test "with an object" do
      assert Utils.get_actor(%{
               "actor" => %{"id" => "https://somewhere.tld/@someone", "type" => "Person"}
             }) ==
               "https://somewhere.tld/@someone"
    end

    test "with an invalid object" do
      assert_raise ArgumentError,
                   "Object contains an actor object with invalid type: \"Else\"",
                   fn ->
                     Utils.get_actor(%{
                       "actor" => %{"id" => "https://somewhere.tld/@someone", "type" => "Else"}
                     })
                   end
    end

    test "with a list" do
      assert Utils.get_actor(%{
               "actor" => ["https://somewhere.tld/@someone", "https://somewhere.else/@other"]
             }) ==
               "https://somewhere.tld/@someone"
    end

    test "with a list of objects" do
      assert Utils.get_actor(%{
               "actor" => [
                 %{"type" => "Person", "id" => "https://somewhere.tld/@someone"},
                 "https://somewhere.else/@other"
               ]
             }) ==
               "https://somewhere.tld/@someone"
    end

    test "with a list of objects containing an invalid one" do
      assert Utils.get_actor(%{
               "actor" => [
                 %{"type" => "Else", "id" => "https://somewhere.tld/@someone"},
                 "https://somewhere.else/@other"
               ]
             }) ==
               "https://somewhere.else/@other"
    end

    test "with an empty list" do
      assert_raise ArgumentError,
                   "Object contains not actor information",
                   fn ->
                     Utils.get_actor(%{
                       "actor" => []
                     })
                   end
    end

    test "fallbacks to attributed_to" do
      assert Utils.get_actor(%{
               "actor" => nil,
               "attributedTo" => "https://somewhere.tld/@someone"
             }) == "https://somewhere.tld/@someone"
    end

    test "with no actor information" do
      assert_raise ArgumentError,
                   "Object contains both actor and attributedTo fields being null",
                   fn ->
                     Utils.get_actor(%{
                       "actor" => nil,
                       "attributedTo" => nil
                     })
                   end
    end
  end
end
