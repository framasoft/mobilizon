defmodule Mobilizon.Service.Activity.Renderer.Resource do
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
          resource: title(activity),
          group: group(activity),
          subject_params: activity.subject_params
        }),
      resource_url: resource_url(activity)
    }
  end

  defp text(:resource_created, %{subject_params: subject_params} = args) do
    if subject_params["is_folder"] do
      dgettext("activity", "%{profile} created the folder %{resource} in group %{group}.", args)
    else
      dgettext(
        "activity",
        "%{profile} created the resource %{resource} in group %{group}.",
        args
      )
    end
  end

  defp text(:resource_renamed, %{subject_params: subject_params} = args) do
    if subject_params["is_folder"] do
      dgettext(
        "activity",
        "%{profile} renamed the folder from %{old_resource_title} to %{resource} in group %{group}.",
        Map.put(args, :old_resource_title, subject_params["old_resource_title"])
      )
    else
      dgettext(
        "activity",
        "%{profile} renamed the resource from %{old_resource_title} to %{resource} in group %{group}.",
        Map.put(args, :old_resource_title, subject_params["old_resource_title"])
      )
    end
  end

  defp text(:resource_moved, %{subject_params: subject_params} = args) do
    if subject_params["is_folder"] do
      dgettext("activity", "%{profile} moved the folder %{resource} in group %{group}.", args)
    else
      dgettext("activity", "%{profile} moved the resource %{resource} in group %{group}.", args)
    end
  end

  defp text(:resource_deleted, %{subject_params: subject_params} = args) do
    if subject_params["is_folder"] do
      dgettext("activity", "%{profile} deleted the folder %{resource} in group %{group}.", args)
    else
      dgettext("activity", "%{profile} deleted the resource %{resource} in group %{group}.", args)
    end
  end

  defp resource_url(activity) do
    ~p"/resource/#{activity.subject_params["resource_uuid"]}"
    |> url()
    |> URI.decode()
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["resource_title"]
  defp group(%Activity{group: group}), do: Actor.display_name(group)
end
