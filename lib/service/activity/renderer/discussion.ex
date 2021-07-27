defmodule Mobilizon.Service.Activity.Renderer.Discussion do
  @moduledoc """
  Insert a comment activity
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
    title = title(activity)

    case activity.subject do
      :discussion_created ->
        %{
          body:
            dgettext("activity", "%{profile} created the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: discussion_url(activity)
        }

      :discussion_replied ->
        %{
          body:
            dgettext("activity", "%{profile} replied to the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: discussion_url(activity)
        }

      :discussion_mention ->
        %{
          body:
            dgettext("activity", "%{profile} mentionned you in the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: discussion_url(activity)
        }

      :discussion_renamed ->
        %{
          body:
            dgettext("activity", "%{profile} renamed the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: discussion_url(activity)
        }

      :discussion_archived ->
        %{
          body:
            dgettext("activity", "%{profile} archived the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: discussion_url(activity)
        }

      :discussion_deleted ->
        %{
          body:
            dgettext("activity", "%{profile} deleted the discussion %{discussion}.", %{
              profile: profile,
              discussion: title
            }),
          url: nil
        }
    end
  end

  defp discussion_url(activity) do
    Endpoint
    |> Routes.page_url(
      :discussion,
      Actor.preferred_username_and_domain(activity.group),
      activity.subject_params["discussion_slug"]
    )
    |> URI.decode()
  end

  defp profile(%Activity{author: author}), do: Actor.display_name_and_username(author)

  defp title(%Activity{subject_params: %{"discussion_title" => discussion_title}}),
    do: discussion_title
end
