defmodule Mobilizon.Federation.ActivityPub.UtilsTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase

  import Mobilizon.Factory

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
               "published" => reply.published_at |> DateTime.to_iso8601()
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
end
