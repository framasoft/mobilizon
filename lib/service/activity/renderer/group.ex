defmodule Mobilizon.Service.Activity.Renderer.Group do
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
      :post_created ->
        %{
          body:
            dgettext("activity", "The post %{post} was created by %{profile}.", %{
              profile: profile(activity),
              post: title(activity)
            }),
          url: post_url(activity)
        }

      :post_updated ->
        %{
          body:
            dgettext("activity", "The post %{post} was updated by %{profile}.", %{
              profile: profile(activity),
              post: title(activity)
            }),
          url: post_url(activity)
        }

      :post_deleted ->
        %{
          body:
            dgettext("activity", "The post %{post} was deleted by %{profile}.", %{
              profile: profile(activity),
              post: title(activity)
            }),
          url: post_url(activity)
        }
    end
  end

  defp post_url(activity) do
    Routes.page_url(Endpoint, :post, activity.subject_params["post_slug"])
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["post_title"]
end
