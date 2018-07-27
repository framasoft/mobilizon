defmodule EventosWeb.SessionView do
  @moduledoc """
  View for event Sessions
  """
  use EventosWeb, :view
  alias EventosWeb.SessionView

  def render("index.json", %{sessions: sessions}) do
    %{data: render_many(sessions, SessionView, "session.json")}
  end

  def render("show.json", %{session: session}) do
    %{data: render_one(session, SessionView, "session.json")}
  end

  def render("session.json", %{session: session}) do
    %{
      id: session.id,
      title: session.title,
      subtitle: session.subtitle,
      short_abstract: session.short_abstract,
      long_abstract: session.long_abstract,
      language: session.language,
      slides_url: session.slides_url,
      videos_urls: session.videos_urls,
      audios_urls: session.audios_urls
    }
  end
end
