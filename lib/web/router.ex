defmodule Mobilizon.Web.Router do
  @moduledoc """
  Router for mobilizon app
  """
  use Mobilizon.Web, :router

  pipeline :graphql do
    #    plug(:accepts, ["json"])
    plug(Mobilizon.Web.Auth.Pipeline)
  end

  pipeline :well_known do
    plug(:accepts, ["json", "jrd-json"])
  end

  pipeline :activity_pub_signature do
    plug(Mobilizon.Web.Plugs.HTTPSignatures)
    plug(Mobilizon.Web.Plugs.MappedSignatureToIdentity)
  end

  pipeline :relay do
    plug(Mobilizon.Web.Plugs.HTTPSignatures)
    plug(Mobilizon.Web.Plugs.MappedSignatureToIdentity)
    plug(:accepts, ["activity-json", "json"])
  end

  pipeline :activity_pub do
    plug(:accepts, ["activity-json"])
  end

  pipeline :activity_pub_and_html do
    plug(:accepts, ["html", "activity-json"])

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr
    )
  end

  pipeline :atom_and_ical do
    plug(:accepts, ["atom", "ics", "html"])
  end

  pipeline :browser do
    plug(Plug.Static, at: "/", from: "priv/static")

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr
    )

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

    forward("/", Absinthe.Plug,
      schema: Mobilizon.GraphQL.Schema,
      analyze_complexity: true,
      max_complexity: 200
    )
  end

  scope "/.well-known", Mobilizon.Web do
    pipe_through(:well_known)

    get("/host-meta", WebFingerController, :host_meta)
    get("/webfinger", WebFingerController, :webfinger)
    get("/nodeinfo", NodeInfoController, :schemas)
    get("/nodeinfo/:version", NodeInfoController, :nodeinfo)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:activity_pub_and_html)
    pipe_through(:activity_pub_signature)

    get("/@:name", PageController, :actor)
    get("/events/me", PageController, :index)
    get("/events/:uuid", PageController, :event)
    get("/comments/:uuid", PageController, :comment)
    get("/resource/:uuid", PageController, :resource, as: "resource")
    get("/todo-list/:uuid", PageController, :todo_list, as: "todo_list")
    get("/todo/:uuid", PageController, :todo, as: "todo")
    get("/@:name/resources", PageController, :resources)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:activity_pub)

    get("/@:name/outbox", ActivityPubController, :outbox)
    get("/@:name/following", ActivityPubController, :following)
    get("/@:name/followers", ActivityPubController, :followers)
    get("/@:name/members", ActivityPubController, :members)
    get("/@:name/todo-lists", ActivityPubController, :todo_lists)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:activity_pub_signature)
    post("/@:name/inbox", ActivityPubController, :inbox)
    post("/inbox", ActivityPubController, :inbox)
  end

  scope "/relay", Mobilizon.Web do
    pipe_through(:relay)

    get("/", ActivityPubController, :relay)
    post("/inbox", ActivityPubController, :inbox)
  end

  ## FEED

  scope "/", Mobilizon.Web do
    pipe_through(:atom_and_ical)

    get("/@:name/feed/:format", FeedController, :actor)
    get("/events/:uuid/export/:format", FeedController, :event)
    get("/events/going/:token/:format", FeedController, :going)
  end

  ## MOBILIZON
  scope "/graphiql" do
    pipe_through(:graphql)
    forward("/", Absinthe.Plug.GraphiQL, schema: Mobilizon.GraphQL.Schema)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:browser)

    # Because the "/events/:uuid" route caches all these, we need to force them
    get("/events/create", PageController, :index)
    get("/events/list", PageController, :index)
    get("/events/me", PageController, :index)
    get("/events/explore", PageController, :index)
    get("/events/:uuid/edit", PageController, :index)

    # This is a hack to ease link generation into emails
    get("/moderation/reports/:id", PageController, :index, as: "moderation_report")

    get("/participation/email/confirm/:token", PageController, :index,
      as: "participation_email_confirmation"
    )

    get("/validate/email/:token", PageController, :index, as: "user_email_validation")
    get("/groups/me", PageController, :index, as: "my_groups")

    get("/interact", PageController, :interact)

    get("/auth/:provider", AuthController, :request)
    get("/auth/:provider/callback", AuthController, :callback)
    post("/auth/:provider/callback", AuthController, :callback)
  end

  scope "/proxy/", Mobilizon.Web do
    pipe_through(:remote_media)

    get("/:sig/:url", MediaProxyController, :remote)
    get("/:sig/:url/:filename", MediaProxyController, :remote)
  end

  if Mix.env() in [:dev, :e2e] do
    # If using Phoenix
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:browser)

    get("/*path", PageController, :index)
  end
end
