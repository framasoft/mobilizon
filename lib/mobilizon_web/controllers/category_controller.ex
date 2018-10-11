defmodule MobilizonWeb.CategoryController do
  @moduledoc """
  Controller for Categories
  """
  use MobilizonWeb, :controller

  alias Mobilizon.Events
  alias Mobilizon.Events.Category

  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params) do
    categories = Events.list_categories()
    render(conn, "index.json", categories: categories)
  end

  def create(conn, %{"category" => category_params}) do
    with {:ok, %Category{} = category} <- Events.create_category(category_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", category_path(conn, :show, category))
      |> render("show.json", category: category)
    end
  end

  def show(conn, %{"id" => id}) do
    category = Events.get_category!(id)
    render(conn, "show.json", category: category)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Events.get_category!(id)

    with {:ok, %Category{} = category} <- Events.update_category(category, category_params) do
      render(conn, "show.json", category: category)
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Events.get_category!(id)

    with {:ok, %Category{}} <- Events.delete_category(category) do
      send_resp(conn, :no_content, "")
    end
  end
end
