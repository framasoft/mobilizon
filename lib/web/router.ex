defmodule Mobilizon.Web.Router do
  @moduledoc """
  Router for mobilizon app
  """
  use Mobilizon.Web, :router
  import Mobilizon.Web.RequestContext

  pipeline :graphql do
    #    plug(:accepts, ["json"])
    plug(:put_request_context)
    plug(Mobilizon.Web.Auth.Pipeline)
    plug(Mobilizon.Web.Plugs.SetLocalePlug)
  end

  pipeline :graphiql do
    plug(Mobilizon.Web.Auth.Pipeline)
    plug(Mobilizon.Web.Plugs.SetLocalePlug)

    plug(Mobilizon.Web.Plugs.HTTPSecurityPlug,
      script_src: ["cdn.jsdelivr.net 'sha256-zkCwvTwqwJMew/8TKv7bTLh94XRSNBvT/o/NZCuf5Kc='"],
      style_src: ["cdn.jsdelivr.net 'unsafe-inline'"],
      font_src: ["cdn.jsdelivr.net"]
    )
  end

  pipeline :host_meta do
    plug(:put_request_context)
    plug(:accepts, ["xrd-xml"])
  end

  pipeline :well_known do
    plug(:put_request_context)
    plug(:accepts, ["json", "jrd-json"])
  end

  pipeline :activity_pub_signature do
    plug(:put_request_context)
    plug(Mobilizon.Web.Plugs.HTTPSignatures)
    plug(Mobilizon.Web.Plugs.MappedSignatureToIdentity)
  end

  pipeline :relay do
    plug(:put_request_context)
    plug(Mobilizon.Web.Plugs.HTTPSignatures)
    plug(Mobilizon.Web.Plugs.MappedSignatureToIdentity)
    plug(:accepts, ["activity-json", "json"])
  end

  pipeline :activity_pub do
    plug(:put_request_context)
    plug(:accepts, ["activity-json"])
  end

  pipeline :activity_pub_and_html do
    plug(:put_request_context)
    plug(:accepts, ["html", "activity-json"])
    plug(:put_secure_browser_headers)

    plug(Mobilizon.Web.Plugs.SetLocalePlug)

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr,
      no_match_log_level: :debug
    )
  end

  pipeline :atom_and_ical do
    plug(:put_request_context)
    plug(:put_secure_browser_headers)
    plug(:accepts, ["atom", "ics", "html", "xml"])
  end

  pipeline :browser do
    plug(:put_request_context)

    plug(Mobilizon.Web.Plugs.SetLocalePlug)

    plug(Cldr.Plug.AcceptLanguage,
      cldr_backend: Mobilizon.Cldr,
      no_match_log_level: :debug
    )

    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope "/exports", Mobilizon.Web do
    pipe_through(:browser)
    get("/:format/:file", ExportController, :export)
  end

  scope "/api" do
    pipe_through(:graphql)

    forward("/", Absinthe.Plug,
      schema: Mobilizon.GraphQL.Schema,
      analyze_complexity: true,
      max_complexity: 300
    )
  end

  scope "/.well-known", Mobilizon.Web do
    pipe_through(:host_meta)

    get("/host-meta", WebFingerController, :host_meta)
  end

  scope "/.well-known", Mobilizon.Web do
    pipe_through(:well_known)

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
    get("/conversations/:id", PageController, :conversation)
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
    get("/feed/instance/:format", FeedController, :instance)
  end

  ## MOBILIZON
  scope "/graphiql" do
    pipe_through(:graphiql)

    forward("/", Absinthe.Plug.GraphiQL,
      schema: Mobilizon.GraphQL.Schema,
      socket: Mobilizon.Web.GraphQLSocket,
      interface: :playground
    )
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

    get(
      "/participation/email/cancel/:uuid/:token",
      PageController,
      :participation_email_cancellation
    )

    get("/validate/email/:token", PageController, :user_email_validation)

    get("/groups/me", PageController, :my_groups)

    get("/interact", PageController, :interact)

    get("/auth/:provider", AuthController, :request)
    # Have a look at https://github.com/ueberauth/ueberauth/issues/125 some day
    # Also possible CSRF issue
    get("/auth/:provider/callback", AuthController, :callback)
    post("/auth/:provider/callback", AuthController, :callback)

    post("/apps", ApplicationController, :create_application)
    get("/oauth/authorize", ApplicationController, :authorize)
    get("/oauth/autorize_approve", PageController, :authorize)
    get("/login/device", PageController, :auth_device)
  end

  pipeline :login do
    plug(:accepts, ["html", "json"])
  end

  scope "/", Mobilizon.Web do
    pipe_through(:login)

    post("/login/device/code", ApplicationController, :device_code)
    post("/oauth/token", ApplicationController, :generate_access_token)
    post("/oauth/revoke", ApplicationController, :revoke_token)
  end

  scope "/proxy/", Mobilizon.Web do
    get("/:sig/:url", MediaProxyController, :remote)
    get("/:sig/:url/:filename", MediaProxyController, :remote)
  end

  if Application.compile_env(:mobilizon, :env) in [:dev, :e2e] do
    # If using Phoenix
    forward("/sent_emails", Plug.Swoosh.MailboxPreview)
  end

  scope "/", Mobilizon.Web do
    pipe_through(:browser)

    get("/*path", PageController, :index)
  end
end
