defmodule EventosWeb.Router do
  use EventosWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
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

    post "/users", UserController, :register
    post "/login", UserSessionController, :sign_in
    resources "/groups", GroupController, only: [:index, :show]
    resources "/events", EventController, only: [:index, :show]
    resources "/accounts", AccountController, only: [:index, :show]
    resources "/tags", TagController, only: [:index, :show]
    resources "/categories", CategoryController, only: [:index, :show]
    resources "/sessions", SessionController, only: [:index, :show]
    resources "/tracks", TrackController, only: [:index, :show]
  end

  # Other scopes may use custom stacks.
  scope "/api", EventosWeb do
     pipe_through :api_auth

     get "/user", UserController, :show_current_account
     post "/sign-out", UserSessionController, :sign_out
     resources "/users", UserController, except: [:new, :edit, :show]
     resources "/accounts", AccountController, except: [:new, :edit]
     resources "/events", EventController
     resources "/categories", CategoryController
     resources "/tags", TagController
     resources "/event_accounts", EventAccountsController
     resources "/event_requests", EventRequestController
     resources "/groups", GroupController, except: [:index]
     resources "/group_accounts", GroupAccountController
     resources "/group_requests", GroupRequestController
     resources "/sessions", SessionController, except: [:new, :edit]
     resources "/tracks", TrackController, except: [:new, :edit]
  end

  scope "/", EventosWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
