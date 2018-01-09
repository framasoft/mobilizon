defmodule EventosWeb.Router do
  use EventosWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
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
    post "/login", SessionController, :sign_in
    resources "/groups", GroupController, only: [:index]
  end

  # Other scopes may use custom stacks.
  scope "/api", EventosWeb do
     pipe_through :api_auth

     post "/sign-out", SessionController, :sign_out
     resources "/users", UserController
     resources "/accounts", AccountController
     resources "/events", EventController
     resources "/categories", CategoryController
     resources "/tags", TagController
     resources "/event_accounts", EventAccountsController
     resources "/event_requests", EventRequestController
     resources "/groups", GroupController, except: [:index]
     resources "/group_accounts", GroupAccountController
     resources "/group_requests", GroupRequestController
  end

  scope "/", EventosWeb do
    pipe_through :browser

    get "/*path", AppController, :app
  end
end
