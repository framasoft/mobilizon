defmodule EventosWeb.Router do
  use EventosWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser
    coherence_routes()
  end

  # Add this block
  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/", EventosWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController
    resources "/accounts", AccountController
    resources "/events", EventController
    resources "/categories", CategoryController
    resources "/tags", TagController
    resources "/event_accounts", EventAccountsController
    resources "/event_requests", EventRequestController
    resources "/groups", GroupController
    resources "/group_accounts", GroupAccountController
    resources "/group_requests", GroupRequestController
  end

  scope "/", EventosWeb do
    pipe_through :protected
    # Add protected routes below
  end

  # Other scopes may use custom stacks.
  scope "/api", EventosWeb do
     pipe_through :api
  end
end
