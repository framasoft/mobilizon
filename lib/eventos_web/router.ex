defmodule EventosWeb.Router do
  @moduledoc """
  Router for eventos app
  """
  use EventosWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :well_known do
    plug(:accepts, ["json/application", "jrd-json", "application/json"])
  end

  pipeline :activity_pub do
    plug(:accepts, ["activity-json"])
    plug(EventosWeb.HTTPSignaturePlug)
  end

  pipeline :api_auth do
    plug(:accepts, ["json"])
    plug(EventosWeb.AuthPipeline)
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

  scope "/api", EventosWeb do
    pipe_through(:api)

    scope "/v1" do
      post("/users", UserController, :register)
      get("/users/validate/:token", UserController, :validate)
      post("/users/resend", UserController, :resend_confirmation)

      post("/users/password-reset/send", UserController, :send_reset_password)
      post("/users/password-reset/post", UserController, :reset_password)

      post("/login", UserSessionController, :sign_in)
      get("/groups", GroupController, :index)
      get("/events", EventController, :index)
      get("/events/all", EventController, :index_all)
      get("/events/search/:name", EventController, :search)
      get("/events/:uuid/ics", EventController, :export_to_ics)
      get("/events/:uuid/tracks", TrackController, :show_tracks_for_event)
      get("/events/:uuid/sessions", SessionController, :show_sessions_for_event)
      get("/events/:uuid", EventController, :show)
      get("/comments/:uuid", CommentController, :show)
      get("/bots/:id", BotController, :show)
      get("/bots", BotController, :index)

      get("/actors", ActorController, :index)
      get("/actors/search/:name", ActorController, :search)
      get("/actors/:name", ActorController, :show)

      resources("/followers", FollowerController, except: [:new, :edit])

      resources("/tags", TagController, only: [:index, :show])
      resources("/categories", CategoryController, only: [:index, :show])
      resources("/sessions", SessionController, only: [:index, :show])
      resources("/tracks", TrackController, only: [:index, :show])
      resources("/addresses", AddressController, only: [:index, :show])

      get("/search/:name", SearchController, :search)

      scope "/nodeinfo" do
        pipe_through(:nodeinfo)

        get("/:version", NodeinfoController, :nodeinfo)
      end
    end
  end

  # Authentificated API
  scope "/api", EventosWeb do
    pipe_through(:api_auth)

    scope "/v1" do
      get("/user", UserController, :show_current_actor)
      post("/sign-out", UserSessionController, :sign_out)
      resources("/users", UserController, except: [:new, :edit, :show])
      post("/actors", ActorController, :create)
      patch("/actors/:name", ActorController, :update)
      post("/events", EventController, :create)
      patch("/events/:uuid", EventController, :update)
      put("/events/:uuid", EventController, :update)
      delete("/events/:uuid", EventController, :delete)
      post("/events/:uuid/join", ParticipantController, :join)
      post("/comments", CommentController, :create)
      patch("/comments/:uuid", CommentController, :update)
      put("/comments/:uuid", CommentController, :update)
      delete("/comments/:uuid", CommentController, :delete)
      resources("/bots", BotController, except: [:new, :edit, :show, :index])
      post("/groups", GroupController, :create)
      post("/groups/:name/join", GroupController, :join)
      resources("/members", MemberController)
      resources("/sessions", SessionController, except: [:index, :show])
      resources("/tracks", TrackController, except: [:index, :show])
      get("/tracks/:id/sessions", SessionController, :show_sessions_for_track)
      resources("/categories", CategoryController)
      resources("/tags", TagController)
      resources("/addresses", AddressController, except: [:index, :show])
    end
  end

  scope "/.well-known", EventosWeb do
    pipe_through(:well_known)

    get("/host-meta", WebFingerController, :host_meta)
    get("/webfinger", WebFingerController, :webfinger)
    get("/nodeinfo", NodeinfoController, :schemas)
  end

  scope "/", EventosWeb do
    pipe_through(:activity_pub)

    get("/@:name", ActivityPubController, :actor)
    get("/@:name/outbox", ActivityPubController, :outbox)
    get("/@:name/following", ActivityPubController, :following)
    get("/@:name/followers", ActivityPubController, :followers)
    get("/events/:uuid", ActivityPubController, :event)
    get("/comments/:uuid", ActivityPubController, :event)
    post("/@:name/inbox", ActivityPubController, :inbox)
    post("/inbox", ActivityPubController, :inbox)
  end

  if Mix.env() == :dev do
    # If using Phoenix
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/", EventosWeb do
    pipe_through(:browser)

    get("/*path", PageController, :index)
  end
end
