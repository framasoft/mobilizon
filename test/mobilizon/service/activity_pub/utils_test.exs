defmodule Mobilizon.Service.ActivityPub.UtilsTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Service.ActivityPub.{Converter, Utils}

  alias MobilizonWeb.Endpoint
  alias MobilizonWeb.Router.Helpers, as: Routes

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
               "id" => Routes.page_url(Endpoint, :comment, reply.uuid),
               "inReplyTo" => comment.url,
               "attributedTo" => reply.actor.url
             } == Converter.Comment.model_to_as(reply)
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
