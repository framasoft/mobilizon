defmodule Mobilizon.Service.Notifier.Filter do
  @moduledoc """
  Module to filter activities to notify according to user's activity settings
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Users
  alias Mobilizon.Users.{ActivitySetting, User}

  @type method :: String.t()

  @spec can_send_activity?(Activity.t(), method(), User.t(), function()) :: boolean()
  def can_send_activity?(%Activity{} = activity, method, %User{} = user, get_default) do
    case map_activity_to_activity_setting(activity) do
      false ->
        false

      key when is_binary(key) ->
        user |> Users.activity_setting(key, method) |> enabled?(key, get_default)
    end
  end

  @spec enabled?(ActivitySetting.t() | nil, String.t(), function()) :: boolean()
  defp enabled?(nil, activity_setting, get_default), do: get_default.(activity_setting)
  defp enabled?(%ActivitySetting{enabled: enabled}, _activity_setting, _get_default), do: enabled

  # Comment mention
  defp map_activity_to_activity_setting(%Activity{subject: :event_comment_mention}),
    do: "event_comment_mention"

  # Participation
  @spec map_activity_to_activity_setting(Activity.t()) :: String.t() | false
  defp map_activity_to_activity_setting(%Activity{subject: :participation_event_updated}),
    do: "participation_event_updated"

  defp map_activity_to_activity_setting(%Activity{subject: :participation_event_comment}),
    do: "participation_event_comment"

  # Organizers
  defp map_activity_to_activity_setting(%Activity{subject: :event_new_pending_participation}),
    do: "event_new_pending_participation"

  defp map_activity_to_activity_setting(%Activity{subject: :event_new_participation}),
    do: "event_new_participation"

  # Event
  defp map_activity_to_activity_setting(%Activity{subject: :event_created}), do: "event_created"
  defp map_activity_to_activity_setting(%Activity{type: :event}), do: "event_updated"

  # Post
  defp map_activity_to_activity_setting(%Activity{subject: :post_created}), do: "post_published"
  defp map_activity_to_activity_setting(%Activity{type: :post}), do: "post_updated"

  # Discussion
  defp map_activity_to_activity_setting(%Activity{type: :discussion}), do: "discussion_updated"

  # Resource
  defp map_activity_to_activity_setting(%Activity{type: :resource}), do: "resource_updated"

  # Member
  defp map_activity_to_activity_setting(%Activity{subject: :member_request}),
    do: "member_request"

  defp map_activity_to_activity_setting(%Activity{type: :member}), do: "member"

  defp map_activity_to_activity_setting(_), do: false
end
