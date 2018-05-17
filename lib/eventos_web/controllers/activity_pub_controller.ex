defmodule EventosWeb.ActivityPubController do
  use EventosWeb, :controller
  alias Eventos.{Accounts, Accounts.Account, Events, Events.Event}
  alias EventosWeb.ActivityPub.{ObjectView, AccountView}
  alias Eventos.Service.ActivityPub
  alias Eventos.Service.Federator

  require Logger

  action_fallback(:errors)

  def account(conn, %{"username" => username}) do
    with %Account{} = account <- Accounts.get_account_by_username(username) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(AccountView.render("account.json", %{account: account}))
    end
  end

  def event(conn, %{"username" => username, "slug" => slug}) do
    with %Event{} = event <- Events.get_event_full_by_username_and_slug!(username, slug) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("event.json", %{event: event}))
    end
  end

#  def following(conn, %{"username" => username, "page" => page}) do
#    with %Account{} = account <- Accounts.get_account_by_username(username) do
#      {page, _} = Integer.parse(page)
#
#      conn
#      |> put_resp_header("content-type", "application/activity+json")
#      |> json(UserView.render("following.json", %{account: account, page: page}))
#    end
#  end
#
#  def following(conn, %{"nickname" => nickname}) do
#    with %User{} = user <- User.get_cached_by_nickname(nickname),
#         {:ok, user} <- Pleroma.Web.WebFinger.ensure_keys_present(user) do
#      conn
#      |> put_resp_header("content-type", "application/activity+json")
#      |> json(UserView.render("following.json", %{user: user}))
#    end
#  end
#
#  def followers(conn, %{"nickname" => nickname, "page" => page}) do
#    with %User{} = user <- User.get_cached_by_nickname(nickname),
#         {:ok, user} <- Pleroma.Web.WebFinger.ensure_keys_present(user) do
#      {page, _} = Integer.parse(page)
#
#      conn
#      |> put_resp_header("content-type", "application/activity+json")
#      |> json(UserView.render("followers.json", %{user: user, page: page}))
#    end
#  end
#
#  def followers(conn, %{"nickname" => nickname}) do
#    with %User{} = user <- User.get_cached_by_nickname(nickname),
#         {:ok, user} <- Pleroma.Web.WebFinger.ensure_keys_present(user) do
#      conn
#      |> put_resp_header("content-type", "application/activity+json")
#      |> json(UserView.render("followers.json", %{user: user}))
#    end
#  end

  def outbox(conn, %{"username" => username, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Account{} = account <- Accounts.get_account_by_username(username) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(AccountView.render("outbox.json", %{account: account, page: page}))
    end
  end

  def outbox(conn, %{"username" => username}) do
    outbox(conn, %{"username" => username, "page" => "0"})
  end

  # TODO: Ensure that this inbox is a recipient of the message
  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
    Federator.enqueue(:incoming_ap_doc, params)
    json(conn, "ok")
  end

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if !String.contains?(headers["signature"] || "", params["actor"]) do
      Logger.info("Signature not from author, relayed message, fetching from source")
      ActivityPub.fetch_event_from_url(params["object"]["id"])
    else
      Logger.info("Signature error")
      Logger.info("Could not validate #{params["actor"]}")
      Logger.info(inspect(conn.req_headers))
    end

    json(conn, "ok")
  end

  def errors(conn, _e) do
    conn
    |> put_status(500)
    |> json("error")
  end
end
