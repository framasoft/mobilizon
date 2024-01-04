defmodule Mobilizon.Web.EmailView do
  use Phoenix.View,
    root: "lib/web/templates",
    pattern: "**/*",
    namespace: Mobilizon.Web

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Address
  alias Mobilizon.Service.DateTime, as: DateTimeRenderer
  alias Mobilizon.Service.Formatter.{HTML, Text}
  use Mobilizon.Web, :verified_routes
  import Mobilizon.Web.Gettext
  import Mobilizon.Service.Metadata.Utils, only: [process_description: 1]
  import Phoenix.HTML, only: [raw: 1, html_escape: 1, safe_to_string: 1]

  defdelegate datetime_to_string(datetime, locale \\ "en", format \\ :medium),
    to: DateTimeRenderer

  defdelegate datetime_to_time_string(datetime, locale \\ "en", format \\ :short),
    to: DateTimeRenderer

  defdelegate datetime_to_date_string(datetime, locale \\ "en", format \\ :short),
    to: DateTimeRenderer

  defdelegate datetime_tz_convert(datetime, timezone), to: DateTimeRenderer
  defdelegate datetime_relative(datetime, locale \\ "en"), to: DateTimeRenderer
  defdelegate render_address(address), to: Address
  defdelegate same_day?(one, two), to: DateTimeRenderer
  defdelegate display_name(actor), to: Actor
  defdelegate preferred_username_and_domain(actor), to: Actor

  @spec escape_html(String.t()) :: String.t()
  def escape_html(string) do
    string
    |> html_escape()
    |> safe_to_string()
  end

  @spec sanitize_to_basic_html(String.t()) :: String.t()
  def sanitize_to_basic_html(html) do
    case HTML.basic_html(html) do
      {:ok, html} -> html
      _ -> ""
    end
  end

  defdelegate html_to_text(html), to: HTML

  def mail_quote(text) do
    # https://www.emailonacid.com/blog/article/email-development/line-length-in-html-email/
    Text.quote_paragraph(text, 78)
  end

  def escaped_display_name_and_username(actor) do
    actor
    |> display_name_and_username()
    |> escape_html()
  end

  def display_name_and_username(%Actor{preferred_username: "anonymous"}) do
    dgettext("activity", "An anonymous profile")
  end

  def display_name_and_username(actor), do: Actor.display_name_and_username(actor)
end
