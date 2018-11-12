defmodule MobilizonWeb.Router do
  @moduledoc """
  Router for mobilizon app
  """
  use MobilizonWeb, :router

  pipeline :graphql do
    plug(:accepts, ["json"])
    plug(MobilizonWeb.AuthPipeline)
  end

  pipeline :well_known do
    plug(:accepts, ["json", "jrd-json"])
  end

  pipeline :activity_pub_signature do
    plug(:accepts, ["activity-json", "html"])
    plug(MobilizonWeb.HTTPSignaturePlug)
  end

  pipeline :activity_pub do
    plug(:accepts, ["activity-json", "html"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :nodeinfo do
    plug(:accepts, ["html", "application/json"])
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
    pipe_through(:activity_pub)

    get("/@:name", ActivityPubController, :actor)
    get("/@:name/outbox", ActivityPubController, :outbox)
    get("/@:name/following", ActivityPubController, :following)
    get("/@:name/followers", ActivityPubController, :followers)
    get("/events/:uuid", ActivityPubController, :event)
    get("/comments/:uuid", ActivityPubController, :comment)
  end

  scope "/", MobilizonWeb do
    pipe_through(:activity_pub_signature)
    post("/@:name/inbox", ActivityPubController, :inbox)
    post("/inbox", ActivityPubController, :inbox)
  end

  if Mix.env() == :dev do
    # If using Phoenix
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/", MobilizonWeb do
    pipe_through(:browser)

    forward("/uploads", UploadPlug)
    get("/*path", PageController, :index)
  end
end
