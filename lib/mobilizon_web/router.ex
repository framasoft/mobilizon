defmodule MobilizonWeb.Router do
  @moduledoc """
  Router for mobilizon app
  """
  use MobilizonWeb, :router

  pipeline :graphql do
    #    plug(:accepts, ["json"])
    plug(MobilizonWeb.AuthPipeline)
  end

  pipeline :well_known do
    plug(:accepts, ["json", "jrd-json"])
  end

  pipeline :activity_pub_signature do
    plug(:accepts, ["activity-json", "html"])
    plug(MobilizonWeb.HTTPSignaturePlug)
  end

  pipeline :relay do
    plug(:accepts, ["activity-json", "json"])
  end

  pipeline :activity_pub do
    plug(:accepts, ["activity-json"])
  end

  pipeline :activity_pub_and_html do
    plug(:accepts, ["html", "activity-json"])
  end

  pipeline :atom_and_ical do
    plug(:accepts, ["atom", "ics", "html"])
  end

  pipeline :browser do
    plug(Plug.Static, at: "/", from: "priv/static")
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :remote_media do
  end

  scope "/api" do
    pipe_through(:graphql)

    forward("/", Absinthe.Plug, schema: MobilizonWeb.Schema)
  end

  forward("/graphiql", Absinthe.Plug.GraphiQL, schema: MobilizonWeb.Schema)

  scope "/.well-known", MobilizonWeb do
    pipe_through(:well_known)

    get("/host-meta", WebFingerController, :host_meta)
    get("/webfinger", WebFingerController, :webfinger)
    get("/nodeinfo", NodeInfoController, :schemas)
    get("/nodeinfo/:version", NodeInfoController, :nodeinfo)
  end

  scope "/", MobilizonWeb do
    pipe_through(:atom_and_ical)

    get("/@:name/feed/:format", FeedController, :actor)
    get("/events/:uuid/export/:format", FeedController, :event)
    get("/events/going/:token/:format", FeedController, :going)
  end

  scope "/", MobilizonWeb do
    pipe_through(:browser)

    # Because the "/events/:uuid" route caches all these, we need to force them
    get("/events/create", PageController, :index)
    get("/events/list", PageController, :index)
    get("/events/me", PageController, :index)
    get("/events/explore", PageController, :index)
    get("/events/:uuid/edit", PageController, :index)

    # This is a hack to ease link generation into emails
    get("/moderation/reports/:id", PageController, :index, as: "moderation_report")
  end

  scope "/", MobilizonWeb do
    pipe_through(:activity_pub_and_html)
    get("/@:name", PageController, :actor)
    get("/events/:uuid", PageController, :event)
    get("/comments/:uuid", PageController, :comment)
  end

  scope "/", MobilizonWeb do
    pipe_through(:activity_pub)

    get("/@:name/outbox", ActivityPubController, :outbox)
    get("/@:name/following", ActivityPubController, :following)
    get("/@:name/followers", ActivityPubController, :followers)
  end

  scope "/", MobilizonWeb do
    pipe_through(:activity_pub_signature)
    post("/@:name/inbox", ActivityPubController, :inbox)
    post("/inbox", ActivityPubController, :inbox)
  end

  scope "/relay", MobilizonWeb do
    pipe_through(:relay)

    get("/", ActivityPubController, :relay)
    post("/inbox", ActivityPubController, :inbox)
  end

  scope "/proxy/", MobilizonWeb do
    pipe_through(:remote_media)

    get("/:sig/:url", MediaProxyController, :remote)
    get("/:sig/:url/:filename", MediaProxyController, :remote)
  end

  if Mix.env() in [:dev, :e2e] do
    # If using Phoenix
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/", MobilizonWeb do
    pipe_through(:browser)

    get("/*path", PageController, :index)
  end
end
