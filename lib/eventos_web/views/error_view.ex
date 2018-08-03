defmodule EventosWeb.ErrorView do
  @moduledoc """
  View for errors
  """
  use EventosWeb, :view

  def render("404.html", _assigns) do
    "Page not found"
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
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end
end
