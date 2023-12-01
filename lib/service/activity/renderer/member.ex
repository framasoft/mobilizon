defmodule Mobilizon.Service.Activity.Renderer.Member do
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
          member: member(activity),
          group: group(activity)
        }),
      url: member_url(activity)
    }
  end

  defp text(:member_request, args) do
    dgettext("activity", "%{member} requested to join the group %{group}.", args)
  end

  defp text(:member_invited, args) do
    dgettext("activity", "%{member} was invited by %{profile} to group %{group}.", args)
  end

  defp text(:member_accepted_invitation, args) do
    dgettext("activity", "%{member} accepted the invitation to join the group %{group}.", args)
  end

  defp text(:member_rejected_invitation, args) do
    dgettext("activity", "%{member} rejected the invitation to join the group %{group}.", args)
  end

  defp text(:member_joined, args) do
    dgettext("activity", "%{member} joined the group %{group}.", args)
  end

  defp text(:member_added, args) do
    dgettext("activity", "%{profile} added the member %{member} to group %{group}.", args)
  end

  defp text(:member_approved, args) do
    dgettext(
      "activity",
      "%{profile} approved the membership request from %{member} for group %{group}.",
      args
    )
  end

  defp text(:member_rejected, args) do
    dgettext(
      "activity",
      "%{profile} rejected the membership request from %{member} for group %{group}.",
      args
    )
  end

  defp text(:member_updated, args) do
    dgettext("activity", "%{profile} updated the member %{member} in group %{group}.", args)
  end

  defp text(:member_removed, args) do
    dgettext("activity", "%{profile} excluded member %{member} from the group %{group}.", args)
  end

  defp text(:member_quit, args) do
    dgettext("activity", "%{profile} quit the group %{group}.", args)
  end

  defp member_url(activity) do
    group_url =
      ~p"/@#{Actor.preferred_username_and_domain(activity.group)}" |> url() |> URI.decode()

    "#{group_url}/settings/members"
  end

  defp profile(activity), do: Actor.display_name_and_username(activity.author)

  defp member(activity),
    do:
      activity.subject_params["member_actor_name"] ||
        activity.subject_params["member_actor_federated_username"]

  defp group(%Activity{group: group}), do: Actor.display_name(group)
end
