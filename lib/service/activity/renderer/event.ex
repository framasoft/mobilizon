defmodule Mobilizon.Service.Activity.Renderer.Event do
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

    case activity.subject do
      :event_created ->
        %{
          body:
            dgettext("activity", "The event %{event} was created by %{profile}.", %{
              profile: profile(activity),
              event: title(activity)
            }),
          url: event_url(activity)
        }

      :event_updated ->
        %{
          body:
            dgettext("activity", "The event %{event} was updated by %{profile}.", %{
              profile: profile(activity),
              event: title(activity)
            }),
          url: event_url(activity)
        }

      :event_deleted ->
        %{
          body:
            dgettext("activity", "The event %{event} was deleted by %{profile}.", %{
              profile: profile(activity),
              event: title(activity)
            }),
          url: nil
        }

      :comment_posted ->
        if activity.subject_params["comment_reply_to"] do
          %{
            body:
              dgettext("activity", "%{profile} replied to a comment on the event %{event}.", %{
                profile: profile(activity),
                event: title(activity)
              }),
            url: event_url(activity)
          }
        else
          %{
            body:
              dgettext("activity", "%{profile} posted a comment on the event %{event}.", %{
                profile: profile(activity),
                event: title(activity)
              }),
            url: event_url(activity)
          }
        end
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
  defp title(activity), do: activity.subject_params["event_title"]
end
