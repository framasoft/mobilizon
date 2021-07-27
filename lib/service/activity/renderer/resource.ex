defmodule Mobilizon.Service.Activity.Renderer.Resource do
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

    case activity.subject do
      :resource_created ->
        if activity.subject_params["is_folder"] do
          %{
            body:
              dgettext("activity", "%{profile} created the folder %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        else
          %{
            body:
              dgettext("activity", "%{profile} created the resource %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        end

      :resource_renamed ->
        if activity.subject_params["is_folder"] do
          %{
            body:
              dgettext(
                "activity",
                "%{profile} renamed the folder from %{old_resource_title} to %{resource}.",
                %{
                  profile: profile(activity),
                  resource: title(activity),
                  old_resource_title: activity.subject_params["old_resource_title"]
                }
              ),
            url: resource_url(activity)
          }
        else
          %{
            body:
              dgettext(
                "activity",
                "%{profile} renamed the resource from %{old_resource_title} to %{resource}.",
                %{
                  profile: profile(activity),
                  resource: title(activity),
                  old_resource_title: activity.subject_params["old_resource_title"]
                }
              ),
            url: resource_url(activity)
          }
        end

      :resource_moved ->
        if activity.subject_params["is_folder"] do
          %{
            body:
              dgettext("activity", "%{profile} moved the folder %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        else
          %{
            body:
              dgettext("activity", "%{profile} moved the resource %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        end

      :resource_deleted ->
        if activity.subject_params["is_folder"] do
          %{
            body:
              dgettext("activity", "%{profile} deleted the folder %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        else
          %{
            body:
              dgettext("activity", "%{profile} deleted the resource %{resource}.", %{
                profile: profile(activity),
                resource: title(activity)
              }),
            url: resource_url(activity)
          }
        end
    end
  end

  defp resource_url(activity) do
    Endpoint
    |> Routes.page_url(:resource, activity.subject_params["resource_uuid"])
    |> URI.decode()
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp title(activity), do: activity.subject_params["resource_title"]
end
