defmodule MobilizonWeb.FollowerController do
  use MobilizonWeb, :controller

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Follower

  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params) do
    followers = Actors.list_followers()
    render(conn, "index.json", followers: followers)
  end

  def create(conn, %{"follower" => follower_params}) do
    with {:ok, %Follower{} = follower} <- Actors.create_follower(follower_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", follower_path(conn, :show, follower))
      |> render("show.json", follower: follower)
    end
  end

  def show(conn, %{"id" => id}) do
    follower = Actors.get_follower!(id)
    render(conn, "show.json", follower: follower)
  end

  def update(conn, %{"id" => id, "follower" => follower_params}) do
    follower = Actors.get_follower!(id)

    with {:ok, %Follower{} = follower} <- Actors.update_follower(follower, follower_params) do
      render(conn, "show.json", follower: follower)
    end
  end

  def delete(conn, %{"id" => id}) do
    follower = Actors.get_follower!(id)

    with {:ok, %Follower{}} <- Actors.delete_follower(follower) do
      send_resp(conn, :no_content, "")
    end
  end
end
