defmodule MobilizonWeb.PageView do
  @moduledoc """
  View for our webapp
  """
  use MobilizonWeb, :view
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub.{Converter, Utils}
  alias Mobilizon.Service.Metadata
  alias Mobilizon.Service.MetadataUtils
  alias Mobilizon.Service.Metadata.Instance

  def render("actor.activity-json", %{conn: %{assigns: %{object: actor}}}) do
    public_key = Utils.pem_to_public_key_pem(actor.keys)

    %{
      "id" => Actor.build_url(actor.preferred_username, :page),
      "type" => "Person",
      "following" => Actor.build_url(actor.preferred_username, :following),
      "followers" => Actor.build_url(actor.preferred_username, :followers),
      "inbox" => Actor.build_url(actor.preferred_username, :inbox),
      "outbox" => Actor.build_url(actor.preferred_username, :outbox),
      "preferredUsername" => actor.preferred_username,
      "name" => actor.name,
      "summary" => actor.summary,
      "url" => actor.url,
      "manuallyApprovesFollowers" => actor.manually_approves_followers,
      "publicKey" => %{
        "id" => "#{actor.url}#main-key",
        "owner" => actor.url,
        "publicKeyPem" => public_key
      },
      # TODO : Make have actors have an uuid
      # "uuid" => actor.uuid
      "endpoints" => %{
        "sharedInbox" => actor.shared_inbox_url
      }
      #      "icon" => %{
      #        "type" => "Image",
      #        "url" => User.avatar_url(actor)
      #      },
      #      "image" => %{
      #        "type" => "Image",
      #        "url" => User.banner_url(actor)
      #      }
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: event}}}) do
    event
    |> Converter.Event.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("comment.activity-json", %{conn: %{assigns: %{object: comment}}}) do
    comment = Converter.Comment.model_to_as(comment)

    %{
      "actor" => comment["actor"],
      "uuid" => comment["uuid"],
      # The activity should have attributedTo, not the comment itself
      #      "attributedTo" => comment.attributed_to,
      "type" => "Note",
      "id" => comment["id"],
      "content" => comment["content"],
      "mediaType" => "text/html"
      # "published" => Timex.format!(comment.inserted_at, "{ISO:Extended}"),
      # "updated" => Timex.format!(comment.updated_at, "{ISO:Extended}")
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render(page, %{object: object} = _assigns)
      when page in ["actor.html", "event.html", "comment.html"] do
    with {:ok, index_content} <- File.read(index_file_path()) do
      tags = object |> Metadata.build_tags() |> MetadataUtils.stringify_tags()
      index_content = String.replace(index_content, "<!--server-generated-meta-->", tags)
      {:safe, index_content}
    end
  end

  def render("index.html", _assigns) do
    with {:ok, index_content} <- File.read(index_file_path()) do
      tags = Instance.build_tags() |> MetadataUtils.stringify_tags()
      index_content = String.replace(index_content, "<!--server-generated-meta-->", tags)
      {:safe, index_content}
    end
  end

  defp index_file_path do
    Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html")
  end
end
