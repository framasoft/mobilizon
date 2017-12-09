defmodule EventosWeb.Router do
  use EventosWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug EventosWeb.AuthPipeline
  end

  scope "/api" do
    pipe_through :api

    resources "/users", UserController, only: [:create]
    post "/sign-in", EventosWeb.SessionController, :sign_in
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
     resources "/groups", GroupController
     resources "/group_accounts", GroupAccountController
     resources "/group_requests", GroupRequestController
  end
end
