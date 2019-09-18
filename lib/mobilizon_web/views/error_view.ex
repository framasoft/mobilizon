defmodule MobilizonWeb.ErrorView do
  @moduledoc """
  View for errors
  """
  use MobilizonWeb, :view

  def render("404.html", _assigns) do
    with {:ok, index_content} <- File.read(index_file_path()) do
      {:safe, index_content}
    end
  end

  def render("404.json", _assigns) do
    %{msg: "Resource not found"}
  end

  def render("404.activity-json", _assigns) do
    %{msg: "Resource not found"}
  end

  def render("404.ics", _assigns) do
    "Bad feed"
  end

  def render("404.atom", _assigns) do
    "Bad feed"
  end

  def render("invalid_request.json", _assigns) do
    %{errors: "Invalid request"}
  end

  def render("not_found.json", %{details: details}) do
    %{
      msg: "Resource not found",
      details: details
    }
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, assigns) do
    require Logger
    Logger.warn("Template #{inspect(template)} not found")
    render("500.html", assigns)
  end

  defp index_file_path() do
    Path.join(Application.app_dir(:mobilizon, "priv/static"), "index.html")
  end
end
