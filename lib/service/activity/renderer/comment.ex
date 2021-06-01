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

      :discussion_mention ->
        %{
          body:
            dgettext("activity", "%{profile} mentionned you in the discussion %{discussion}.", %{
              profile: profile,
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_renamed ->
        %{
          body:
            dgettext("activity", "%{profile} renamed the discussion %{discussion}.", %{
              profile: profile,
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_archived ->
        %{
          body:
            dgettext("activity", "%{profile} archived the discussion %{discussion}.", %{
              profile: profile,
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_deleted ->
        %{
          body:
            dgettext("activity", "%{profile} deleted the discussion %{discussion}.", %{
              profile: profile,
              discussion: title(activity)
            }),
          url: nil
        }
    end
  end

  defp discussion_url(activity) do
    Routes.page_url(
      Endpoint,
      :discussion,
      Actor.preferred_username_and_domain(activity.group),
      activity.subject_params["discussion_slug"]
    )
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
  defp title(activity), do: activity.subject_params["discussion_title"]
end
