defmodule Mobilizon.Service.Activity.Renderer.Conversation do
  @moduledoc """
  Render a conversation activity
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Renderer
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  @behaviour Renderer

  @impl Renderer
  def render(%Activity{} = activity, options) do
    locale = Keyword.get(options, :locale, "en")
    Gettext.put_locale(locale)
    profile = profile(activity)

    case activity.subject do
      :conversation_created ->
        %{
          body:
            dgettext(
              "activity",
              "%{profile} sent you a message",
              %{
                profile: profile
              }
            ),
          url: conversation_url(activity)
        }

      :conversation_replied ->
        %{
          body:
            dgettext(
              "activity",
              "%{profile} replied to your message",
              %{
                profile: profile
              }
            ),
          url: conversation_url(activity)
        }

      :conversation_event_announcement ->
        %{
          body:
            dgettext(
              "activity",
              "%{profile} sent a private message about event %{event}",
              %{
                profile: profile,
                event: event_title(activity)
              }
            ),
          url: conversation_url(activity)
        }
    end
  end

  defp conversation_url(activity) do
    Routes.page_url(
      Endpoint,
      :conversation,
      activity.subject_params["conversation_id"]
    )
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp event_title(activity), do: activity.subject_params["conversation_event_title"]
end
