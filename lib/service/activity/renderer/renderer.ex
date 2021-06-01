defmodule Mobilizon.Service.Activity.Renderer do
  @moduledoc """
  Behavior for Activity renderers
  """

  alias Mobilizon.Config
  alias Mobilizon.Activities.Activity

  alias Mobilizon.Service.Activity.Renderer.{
    Comment,
    Discussion,
    Event,
    Group,
    Member,
    Post,
    Resource
  }

  require Logger
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  @type render :: %{body: String.t(), url: String.t()}

  @callback render(entity :: Activity.t(), Keyword.t()) :: render()

  @spec render(Activity.t()) :: render()
  def render(%Activity{} = activity, options \\ []) do
    locale = Keyword.get(options, :locale, "en")
    Gettext.put_locale(locale)

    res =
      activity
      |> do_render(options)
      |> Map.put(:timestamp, DateTime.utc_now() |> DateTime.to_iso8601())
      |> Map.put(:locale, Keyword.get(options, :locale, "en"))
      |> Map.put(
        :title,
        dgettext("activity", "Activity on %{instance}", %{instance: Config.instance_name()})
      )

    Logger.debug("notification to be sent")
    Logger.debug(inspect(res))
    res
  end

  defp do_render(%Activity{type: type} = activity, options) do
    case type do
      :discussion -> Discussion.render(activity, options)
      :event -> Event.render(activity, options)
      :group -> Group.render(activity, options)
      :member -> Member.render(activity, options)
      :post -> Post.render(activity, options)
      :resource -> Resource.render(activity, options)
      :comment -> Comment.render(activity, options)
      _ -> nil
    end
  end
end
