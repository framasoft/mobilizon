defmodule EventosWeb.ActivityPub.AccountView do
  use EventosWeb, :view

  alias EventosWeb.ActivityPub.AccountView
  alias EventosWeb.ActivityPub.ObjectView
  alias EventosWeb.WebFinger
  alias Eventos.Accounts.Account
  alias Eventos.Repo
  alias Eventos.Service.ActivityPub
  alias Eventos.Service.ActivityPub.Transmogrifier
  alias Eventos.Service.ActivityPub.Utils
  import Ecto.Query

  def render("account.json", %{account: account}) do
    {:ok, public_key} = Account.get_public_key_for_account(account)

    %{
      "id" => account.url,
      "type" => "Person",
      #"following" => "#{account.url}/following",
      #"followers" => "#{account.url}/followers",
      "inbox" => "#{account.url}/inbox",
      "outbox" => "#{account.url}/outbox",
      "preferredUsername" => account.username,
      "name" => account.display_name,
      "summary" => account.description,
      "url" => account.url,
      #"manuallyApprovesFollowers" => false,
      "publicKey" => %{
        "id" => "#{account.url}#main-key",
        "owner" => account.url,
        "publicKeyPem" => public_key
      },
      "endpoints" => %{
        "sharedInbox" => "#{EventosWeb.Endpoint.url()}/inbox"
      },
#      "icon" => %{
#        "type" => "Image",
#        "url" => User.avatar_url(account)
#      },
#      "image" => %{
#        "type" => "Image",
#        "url" => User.banner_url(account)
#      }
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("outbox.json", %{account: account, page: page}) do
    {page, no_page} = if page == 0 do
      {1, true}
    else
      {page, false}
    end

     {activities, total} = ActivityPub.fetch_public_activities_for_account(account, page)

    collection =
      Enum.map(activities, fn act ->
        {:ok, data} = Transmogrifier.prepare_outgoing(act.data)
        data
      end)

    iri = "#{account.url}/outbox"

    page = %{
      "id" => "#{iri}?page=#{page}",
      "type" => "OrderedCollectionPage",
      "partOf" => iri,
      "totalItems" => total,
      "orderedItems" => render_many(activities, AccountView, "activity.json", as: :activity),
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

  def render("activity.json", %{activity: activity}) do
    %{
      "id" => activity.data.url <> "/activity",
      "type" => "Create",
      "actor" => activity.data.organizer_account.url,
      "published" => Timex.now(),
      "to" => ["https://www.w3.org/ns/activitystreams#Public"],
      "object" => render_one(activity.data, ObjectView, "event.json", as: :event)
    }
  end

  def collection(collection, iri, page, total \\ nil) do
    offset = (page - 1) * 10
    items = Enum.slice(collection, offset, 10)
    items = Enum.map(items, fn user -> user.ap_id end)
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
