defmodule MobilizonWeb.ActivityPub.ActorView do
  use MobilizonWeb, :view

  alias MobilizonWeb.ActivityPub.ActorView
  alias MobilizonWeb.ActivityPub.ObjectView
  alias MobilizonWeb.WebFinger
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Repo
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Transmogrifier
  alias Mobilizon.Service.ActivityPub.Utils
  alias Mobilizon.Activity
  import Ecto.Query

  def render("actor.json", %{actor: actor}) do
    public_key = Mobilizon.Service.ActivityPub.Utils.pem_to_public_key_pem(actor.keys)

    %{
      "id" => actor.url,
      "type" => "Person",
      "following" => actor.following_url,
      "followers" => actor.followers_url,
      "inbox" => actor.inbox_url,
      "outbox" => actor.outbox_url,
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

  def render("following.json", %{actor: actor, page: page}) do
    actor
    |> Actor.get_followings()
    |> collection(actor.following_url, page)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("following.json", %{actor: actor}) do
    following = Actor.get_followings(actor)

    %{
      "id" => actor.following_url,
      "type" => "OrderedCollection",
      "totalItems" => length(following),
      "first" => collection(following, actor.following_url, 1)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("followers.json", %{actor: actor, page: page}) do
    actor
    |> Actor.get_followers()
    |> collection(actor.followers_url, page)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("followers.json", %{actor: actor}) do
    followers = Actor.get_followers(actor)

    %{
      "id" => actor.followers_url,
      "type" => "OrderedCollection",
      "totalItems" => length(followers),
      "first" => collection(followers, actor.followers_url, 1)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("outbox.json", %{actor: actor, page: page}) do
    {page, no_page} =
      if page == 0 do
        {1, true}
      else
        {page, false}
      end

    {activities, total} = ActivityPub.fetch_public_activities_for_actor(actor, page)

    # collection =
    #   Enum.map(activities, fn act ->
    #     {:ok, data} = Transmogrifier.prepare_outgoing(act.data)
    #     data
    #   end)

    iri = "#{actor.url}/outbox"

    page = %{
      "id" => "#{iri}?page=#{page}",
      "type" => "OrderedCollectionPage",
      "partOf" => iri,
      "totalItems" => total,
      "orderedItems" => render_many(activities, ActorView, "activity.json", as: :activity),
      "next" => "#{iri}?page=#{page + 1}"
    }

    if no_page do
      %{
        "id" => iri,
        "type" => "OrderedCollection",
        "totalItems" => total,
        "first" => page
      }
      |> Map.merge(Utils.make_json_ld_header())
    else
      page |> Map.merge(Utils.make_json_ld_header())
    end
  end

  def render("activity.json", %{activity: %Activity{local: local, data: data} = activity}) do
    %{
      "id" => data["id"],
      "type" =>
        if local do
          "Create"
        else
          "Announce"
        end,
      "actor" => activity.actor,
      # Not sure if needed since this is used into outbox
      "published" => Timex.now(),
      "to" => activity.recipients,
      "object" =>
        case data["type"] do
          "Event" ->
            render_one(data, ObjectView, "event.json", as: :event)

          "Note" ->
            render_one(data, ObjectView, "comment.json", as: :comment)
        end
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def collection(collection, iri, page, total \\ nil) do
    offset = (page - 1) * 10
    items = Enum.slice(collection, offset, 10)
    items = Enum.map(items, fn account -> account.url end)
    total = total || length(collection)

    map = %{
      "id" => "#{iri}?page=#{page}",
      "type" => "OrderedCollectionPage",
      "partOf" => iri,
      "totalItems" => total,
      "orderedItems" => items
    }

    if offset < total do
      Map.put(map, "next", "#{iri}?page=#{page + 1}")
    end
  end
end
