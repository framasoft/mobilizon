defmodule Mobilizon.Service.Activity.Renderer.Comment do
  @moduledoc """
  Insert a comment activity
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Renderer
  use Mobilizon.Web, :verified_routes
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

      :event_new_comment ->
        if activity.subject_params["comment_reply_to"] do
          %{
            body:
              dgettext(
                "activity",
                "%{profile} has posted a new reply under your event %{event}.",
                %{
                  profile: profile,
                  event: event_title(activity)
                }
              ),
            url: event_comment_url(activity)
          }
        else
          %{
            body:
              dgettext(
                "activity",
                "%{profile} has posted a new comment under your event %{event}.",
                %{
                  profile: profile,
                  event: event_title(activity)
                }
              ),
            url: event_comment_url(activity)
          }
        end
    end
  end

  defp event_url(activity) do
    url(~p"/events/#{activity.subject_params["event_uuid"]}")
  end

  defp event_comment_url(activity) do
    "#{event_url(activity)}#comment-#{comment_uuid(activity)}"
  end

  defp comment_uuid(activity) do
    if activity.subject_params["comment_reply_to"] do
      "#{activity.subject_params["reply_to_comment_uuid"]}-#{activity.subject_params["comment_uuid"]}"
    else
      activity.subject_params["comment_uuid"]
    end
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp event_title(activity), do: activity.subject_params["event_title"]
end
