defmodule Mobilizon.Service.Activity.Renderer do
  @moduledoc """
  Behavior for Activity renderers
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Config

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

  @type render :: %{
          body: String.t(),
          url: String.t(),
          timestamp: String.t(),
          locale: String.t(),
          title: String.t()
        }

  @type common_render :: %{body: String.t(), url: String.t()}

  @callback render(activity :: Activity.t(), Keyword.t()) :: common_render()

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

  @types_map %{
    discussion: Discussion,
    conversation: Conversation,
    event: Event,
    group: Group,
    member: Member,
    post: Post,
    resource: Resource,
    comment: Comment
  }

  @spec do_render(Activity.t(), Keyword.t()) :: common_render()
  defp do_render(%Activity{type: type} = activity, options) do
    case Map.get(@types_map, type) do
      nil ->
        nil

      mod ->
        mod.render(activity, options)
    end
  end
end
