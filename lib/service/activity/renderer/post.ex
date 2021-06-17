defmodule Mobilizon.Service.Activity.Renderer.Post do
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
      :discussion_created ->
        %{
          body:
            dgettext("activity", "%{profile} created the discussion %{discussion}.", %{
              profile: profile(activity),
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_replied ->
        %{
          body:
            dgettext("activity", "%{profile} replied to the discussion %{discussion}.", %{
              profile: profile(activity),
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_renamed ->
        %{
          body:
            dgettext("activity", "%{profile} renamed the discussion %{discussion}.", %{
              profile: profile(activity),
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_archived ->
        %{
          body:
            dgettext("activity", "%{profile} archived the discussion %{discussion}.", %{
              profile: profile(activity),
              discussion: title(activity)
            }),
          url: discussion_url(activity)
        }

      :discussion_deleted ->
        %{
          body:
            dgettext("activity", "%{profile} deleted the discussion %{discussion}.", %{
              profile: profile(activity),
              discussion: title(activity)
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

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["discussion_title"]
end
