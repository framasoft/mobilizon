defmodule Mobilizon.Service.Activity.Renderer.Member do
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
      :member_request ->
        %{
          body:
            dgettext("activity", "%{member} requested to join the group.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_invited ->
        %{
          body:
            dgettext("activity", "%{member} was invited by %{profile}.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_accepted_invitation ->
        %{
          body:
            dgettext("activity", "%{member} accepted the invitation to join the group.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_rejected_invitation ->
        %{
          body:
            dgettext("activity", "%{member} rejected the invitation to join the group.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_joined ->
        %{
          body:
            dgettext("activity", "%{member} joined the group.", %{
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_added ->
        %{
          body:
            dgettext("activity", "%{profile} added the member %{member}.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_updated ->
        %{
          body:
            dgettext("activity", "%{profile} updated the member %{member}.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_removed ->
        %{
          body:
            dgettext("activity", "%{profile} excluded member %{member}.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }

      :member_quit ->
        %{
          body:
            dgettext("activity", "%{profile} quit the group.", %{
              profile: profile(activity),
              member: title(activity)
            }),
          url: member_url(activity)
        }
    end
  end

  defp member_url(activity) do
    Routes.page_url(
      Endpoint,
      :discussion,
      Actor.preferred_username_and_domain(activity.group),
      activity.subject_params["discussion_slug"]
    )
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["discussion_title"]
end
