defmodule Mobilizon.Service.Activity.Renderer.Comment do
  @moduledoc """
  Insert a comment activity
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Renderer
  alias Mobilizon.Web.{Endpoint, Gettext}
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  @behaviour Renderer

  @impl Renderer
  def render(%Activity{} = activity, options) do
    locale = Keyword.get(options, :locale, "en")
    Gettext.put_locale(locale)
    profile = profile(activity)

    case activity.subject do
      :event_comment_mention ->
        %{
          body:
            dgettext(
              "activity",
              "%{profile} mentionned you in a comment under event %{event}.",
              %{
                profile: profile,
                event: event_title(activity)
              }
            ),
          url: event_url(activity)
        }

      :participation_event_comment ->
        %{
          body:
            dgettext(
              "activity",
              "%{profile} has posted an announcement under event %{event}.",
              %{
                profile: profile,
                event: event_title(activity)
              }
            ),
          url: event_url(activity)
        }
    end
  end

  defp event_url(activity) do
    Routes.page_url(
      Endpoint,
      :event,
      activity.subject_params["event_uuid"]
    )
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp event_title(activity), do: activity.subject_params["event_title"]
end
