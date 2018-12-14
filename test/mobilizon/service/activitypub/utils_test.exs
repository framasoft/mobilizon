defmodule Mobilizon.Service.Activitypub.UtilsTest do
  use Mobilizon.DataCase
  import Mobilizon.Factory
  alias Mobilizon.Service.ActivityPub.Utils
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  describe "make" do
    test "comment data from struct" do
      comment = insert(:comment)
      reply = insert(:comment, in_reply_to_comment: comment)

      assert %{
               "type" => "Note",
               "to" => ["https://www.w3.org/ns/activitystreams#Public"],
               "content" => reply.text,
               "actor" => reply.actor.url,
               "uuid" => reply.uuid,
               "id" => "#{MobilizonWeb.Endpoint.url()}/comments/#{reply.uuid}",
               "inReplyTo" => comment.url,
               "attributedTo" => reply.actor.url
             } == Utils.make_comment_data(reply)
    end

    test "comment data from map" do
      comment = insert(:comment)
      reply = insert(:comment, in_reply_to_comment: comment)
      to = ["https://www.w3.org/ns/activitystreams#Public"]
      comment_data = Utils.make_comment_data(reply.actor.url, to, reply.text, comment.url)
      assert comment_data["type"] == "Note"
      assert comment_data["to"] == to
      assert comment_data["content"] == reply.text
      assert comment_data["actor"] == reply.actor.url
      assert comment_data["inReplyTo"] == comment.url
    end
  end
end
