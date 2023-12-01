defmodule Mobilizon.Service.Activity.Renderer.Post do
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

    %{
      body:
        text(activity.subject, %{
          profile: profile(activity),
          post: title(activity),
          group: group(activity)
        }),
      url: if(activity.subject !== :post_deleted, do: post_url(activity), else: nil)
    }
  end

  defp text(:post_created, args) do
    dgettext(
      "activity",
      "The post %{post} from group %{group} was published by %{profile}.",
      args
    )
  end

  defp text(:post_updated, args) do
    dgettext(
      "activity",
      "The post %{post} from group %{group} was updated by %{profile}.",
      args
    )
  end

  defp text(:post_deleted, args) do
    dgettext(
      "activity",
      "The post %{post} from group %{group} was deleted by %{profile}.",
      args
    )
  end

  defp post_url(activity) do
    URI.decode(~p"/p/#{activity.subject_params["post_slug"]}")
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["post_title"]
  defp group(activity), do: Actor.display_name_and_username(activity.group)
end
