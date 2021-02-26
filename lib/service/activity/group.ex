defmodule Mobilizon.Service.Activity.Group do
  @moduledoc """
  Insert a group setting activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(group, options \\ [])

  def insert_activity(
        %Actor{type: :Group, id: group_id},
        options
      ) do
    with %Actor{type: :Group} = group <- Actors.get_actor(group_id),
         subject when not is_nil(subject) <- Keyword.get(options, :subject),
         actor_id <- Keyword.get(options, :actor_id),
         default_updater_actor <- Actors.get_actor(actor_id),
         %Actor{id: actor_id} <-
           Keyword.get(options, :updater_actor, default_updater_actor),
         old_group <- Keyword.get(options, :old_group) do
      ActivityBuilder.enqueue(:build_activity, %{
        "type" => "group",
        "subject" => subject,
        "subject_params" => subject_params(group, subject, old_group),
        "group_id" => group.id,
        "author_id" => actor_id,
        "object_type" => "group",
        "object_id" => to_string(group.id),
        "inserted_at" => DateTime.utc_now()
      })
    else
      _ -> {:ok, nil}
    end
  end

  def insert_activity(_, _), do: {:ok, nil}

  @spec subject_params(Actor.t(), String.t() | nil, Actor.t() | nil) :: map()
  defp subject_params(%Actor{} = group, "group_updated", %Actor{} = old_group) do
    group
    |> subject_params(nil, nil)
    |> maybe_put_old_name_if_updated(old_group.name, group.name)
    |> maybe_put_summary_change_if_updated(old_group.summary, group.summary)
    |> maybe_put_old_visibility_if_updated(old_group.visibility, group.visibility)
    |> maybe_put_old_openness_if_updated(old_group.openness, group.openness)
    |> maybe_put_address_change_if_updated(
      old_group.physical_address_id,
      group.physical_address_id
    )
    |> maybe_put_avatar_change_if_updated(
      old_group.avatar,
      group.avatar
    )
    |> maybe_put_banner_change_if_updated(
      old_group.banner,
      group.banner
    )
    |> maybe_put_manually_approves_followers_change_if_updated(
      old_group.manually_approves_followers,
      group.manually_approves_followers
    )
  end

  defp subject_params(
         %Actor{preferred_username: preferred_username, domain: domain, name: name},
         _,
         _
       ) do
    %{
      group_preferred_username: preferred_username,
      group_name: name,
      group_domain: domain,
      group_changes: []
    }
  end

  @spec maybe_put_old_name_if_updated(map(), String.t(), String.t()) :: map()
  defp maybe_put_old_name_if_updated(params, old_group_name, new_group_name)
       when old_group_name != new_group_name do
    params
    |> Map.update(:group_changes, [], fn changes -> changes ++ [:name] end)
    |> Map.put(:old_group_name, old_group_name)
  end

  defp maybe_put_old_name_if_updated(params, _, _), do: params

  defp maybe_put_summary_change_if_updated(params, old_summary, new_summary)
       when old_summary != new_summary do
    Map.update(params, :group_changes, [], fn changes -> changes ++ [:summary] end)
  end

  defp maybe_put_summary_change_if_updated(params, _, _), do: params

  defp maybe_put_old_visibility_if_updated(params, old_group_visibility, new_group_visibility)
       when old_group_visibility != new_group_visibility do
    params
    |> Map.update(:group_changes, [], fn changes -> changes ++ [:visibility] end)
    |> Map.put(:old_group_visibility, old_group_visibility)
  end

  defp maybe_put_old_visibility_if_updated(params, _, _), do: params

  defp maybe_put_old_openness_if_updated(params, old_group_openness, new_group_openness)
       when old_group_openness != new_group_openness do
    params
    |> Map.update(:group_changes, [], fn changes -> changes ++ [:openness] end)
    |> Map.put(:old_group_openness, old_group_openness)
  end

  defp maybe_put_old_openness_if_updated(params, _, _), do: params

  defp maybe_put_address_change_if_updated(params, old_address_id, new_address_id)
       when old_address_id != new_address_id do
    Map.update(params, :group_changes, [], fn changes -> changes ++ [:address] end)
  end

  defp maybe_put_address_change_if_updated(params, _, _), do: params

  defp maybe_put_avatar_change_if_updated(params, old_avatar, new_avatar)
       when old_avatar != new_avatar do
    Map.update(params, :group_changes, [], fn changes -> changes ++ [:avatar] end)
  end

  defp maybe_put_avatar_change_if_updated(params, _, _), do: params

  defp maybe_put_banner_change_if_updated(params, old_banner, new_banner)
       when old_banner != new_banner do
    Map.update(params, :group_changes, [], fn changes -> changes ++ [:banner] end)
  end

  defp maybe_put_banner_change_if_updated(params, _, _), do: params

  defp maybe_put_manually_approves_followers_change_if_updated(
         params,
         old_group_manually_approves_followers,
         new_group_manually_approves_followers
       )
       when old_group_manually_approves_followers != new_group_manually_approves_followers do
    params
    |> Map.update(:group_changes, [], fn changes -> changes ++ [:manually_approves_followers] end)
    |> Map.put(:old_group_manually_approves_followers, old_group_manually_approves_followers)
  end

  defp maybe_put_manually_approves_followers_change_if_updated(params, _, _), do: params
end
