defmodule EventosWeb.Router do
  @moduledoc """
  Router for eventos app
  """
  use EventosWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :well_known do
    plug :accepts, ["json/application", "jrd-json"]
  end

  pipeline :activity_pub do
    plug :accepts, ["activity-json"]
    plug(EventosWeb.HTTPSignaturePlug)
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug EventosWeb.AuthPipeline
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/api", EventosWeb do
    pipe_through :api

    scope "/v1" do

      post "/users", UserController, :register
      post "/login", UserSessionController, :sign_in
      #resources "/groups", GroupController, only: [:index, :show]
      resources "/events", EventController, only: [:index, :show]
      resources "/comments", CommentController, only: [:show]
      get "/events/:id/ics", EventController, :export_to_ics
      get "/events/:id/tracks", TrackController, :show_tracks_for_event
      get "/events/:id/sessions", SessionController, :show_sessions_for_event
      resources "/actors", ActorController, only: [:index, :show]
      resources "/tags", TagController, only: [:index, :show]
      resources "/categories", CategoryController, only: [:index, :show]
      resources "/sessions", SessionController, only: [:index, :show]
      resources "/tracks", TrackController, only: [:index, :show]
      resources "/addresses", AddressController, only: [:index, :show]
    end
  end

  # Other scopes may use custom stacks.
  scope "/api", EventosWeb do
     pipe_through :api_auth

     scope "/v1" do

       get "/user", UserController, :show_current_actor
       post "/sign-out", UserSessionController, :sign_out
       resources "/users", UserController, except: [:new, :edit, :show]
       resources "/actors", ActorController, except: [:new, :edit]
       resources "/events", EventController
       resources "/comments", CommentController, except: [:new, :edit]
       #post "/events/:id/request", EventRequestController, :create_for_event
       resources "/participant", ParticipantController
       #resources "/requests", EventRequestController
       #resources "/groups", GroupController, except: [:index, :show]
       #post "/groups/:id/request", GroupRequestController, :create_for_group
       resources "/members", MemberController
       #resources "/requests", GroupRequestController
       resources "/sessions", SessionController, except: [:index, :show]
       resources "/tracks", TrackController, except: [:index, :show]
       get "/tracks/:id/sessions", SessionController, :show_sessions_for_track
       resources "/categories", CategoryController
       resources "/tags", TagController
       resources "/addresses", AddressController, except: [:index, :show]
     end
  end

  scope "/.well-known", EventosWeb do
    pipe_through :well_known

    get "/host-meta", WebFingerController, :host_meta
    get "/webfinger", WebFingerController, :webfinger
    get "/nodeinfo", NodeinfoController, :schemas
  end

  scope "/nodeinfo", EventosWeb do
    get("/:version", NodeinfoController, :nodeinfo)
  end

  scope "/", EventosWeb do
    pipe_through :activity_pub

    get "/@:name", ActivityPubController, :actor
    get "/@:name/outbox", ActivityPubController, :outbox
    get "/@:name/following", ActivityPubController, :following
    get "/@:name/followers", ActivityPubController, :followers
    get "/@:name/:slug", ActivityPubController, :event
    post "/@:name/inbox", ActivityPubController, :inbox
    post "/inbox", ActivityPubController, :inbox
  end

  scope "/", EventosWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
