defmodule Mobilizon.Web.Router do
  @moduledoc """
  Router for mobilizon app
  """
  use Mobilizon.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

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
    plug(:put_secure_browser_headers)

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr
    )
  end

  pipeline :atom_and_ical do
    plug(:put_secure_browser_headers)
    plug(:accepts, ["atom", "ics", "html"])
  end

  pipeline :browser do
    plug(Plug.Static, at: "/", from: "priv/static")

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr
    )

    plug(:accepts, ["html"])
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
    get("/events/me", PageController, :my_events)
    get("/events/create", PageController, :create_event)
    get("/events/:uuid", PageController, :event)
    get("/comments/:uuid", PageController, :comment)
    get("/resource/:uuid", PageController, :resource)
    get("/todo-list/:uuid", PageController, :todo_list)
    get("/todo/:uuid", PageController, :todo)
    get("/@:name/todos", PageController, :todos)
    get("/@:name/resources", PageController, :resources)
    get("/@:name/posts", PageController, :posts)
    get("/@:name/discussions", PageController, :discussions)
    get("/@:name/events", PageController, :events)
    get("/p/:slug", PageController, :post)
    get("/@:name/c/:slug", PageController, :discussion)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:activity_pub)
    pipe_through(:activity_pub_signature)

    get("/@:name/outbox", ActivityPubController, :outbox)
    get("/@:name/following", ActivityPubController, :following)
    get("/@:name/followers", ActivityPubController, :followers)
    get("/@:name/members", ActivityPubController, :members)
    get("/member/:uuid", ActivityPubController, :member)
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
    get("/events/create", PageController, :create_event)
    get("/events/list", PageController, :list_events)
    get("/events/me", PageController, :my_events)
    get("/events/:uuid/edit", PageController, :edit_event)

    # This is a hack to ease link generation into emails
    get("/moderation/report/:id", PageController, :moderation_report)

    get("/participation/email/confirm/:token", PageController, :participation_email_confirmation)

    get("/validate/email/:token", PageController, :user_email_validation)

    get("/groups/me", PageController, :my_groups)

    get("/interact", PageController, :interact)

    get("/auth/:provider", AuthController, :request)
    # Have a look at https://github.com/ueberauth/ueberauth/issues/125 some day
    # Also possible CSRF issue
    get("/auth/:provider/callback", AuthController, :callback)
    post("/auth/:provider/callback", AuthController, :callback)
  end

  scope "/proxy/", Mobilizon.Web do
    get("/:sig/:url", MediaProxyController, :remote)
    get("/:sig/:url/:filename", MediaProxyController, :remote)
  end

  if Application.fetch_env!(:mobilizon, :env) in [:dev, :e2e] do
    # If using Phoenix
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:browser)

    get("/*path", PageController, :index)
  end
end
