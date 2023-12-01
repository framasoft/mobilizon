defmodule Mobilizon.Service.Activity.Renderer.Group do
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

    case activity.subject do
      :group_updated ->
        %{
          body:
            dgettext("activity", "The group %{group} was updated by %{profile}.", %{
              profile: profile(activity),
              group: group(activity)
            }),
          url: group_url(activity)
        }
    end
  end

  defp group_url(activity) do
    ~p"/@#{Actor.preferred_username_and_domain(activity.group)}"
    |> url()
    |> URI.decode()
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp group(activity), do: Actor.display_name_and_username(activity.group)
end
