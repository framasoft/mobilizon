defmodule Mobilizon.Web.ErrorView do
  @moduledoc """
  View for errors
  """
  use Mobilizon.Web, :view
  alias Mobilizon.Service.Metadata.Instance
  import Mobilizon.Web.Views.Utils

  def render("404.html", %{conn: conn}) do
    with tags <- Instance.build_tags(),
         {:ok, html} <- inject_tags(tags, get_locale(conn)) do
      html
    else
      {:error, error} ->
        return_error(conn, error)
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

  def render("406.json", _assigns) do
    %{msg: "Not acceptable"}
  end

  def render("500.json", assigns) do
    render("500.html", assigns)
  end

  def render("500.activity-json", assigns) do
    render("500.html", assigns)
  end

  def render("500.html", assigns) do
    Mobilizon.Config.instance_config()
    |> Keyword.get(:default_language, "en")
    |> Gettext.put_locale()

    assigns =
      assigns
      |> Map.update(:details, [], & &1)
      |> Map.put(:instance, Mobilizon.Config.instance_name())
      |> Map.put(:contact, Mobilizon.Config.contact())

    render("500_page.html", assigns)
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, assigns) do
    require Logger
    Logger.warn("Template #{inspect(template)} not found")
    render("500.html", assigns)
  end
end
