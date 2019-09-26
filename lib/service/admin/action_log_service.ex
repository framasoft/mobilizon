defmodule Mobilizon.Service.Admin.ActionLogService do
  @moduledoc """
  Module to handle action log creations.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Admin
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @doc """
  Log an admin action
  """
  @spec log_action(Actor.t(), String.t(), String.t()) :: {:ok, ActionLog.t()}
  def log_action(%Actor{user_id: user_id, id: actor_id}, action, target) do
    with %User{role: role} <- Users.get_user!(user_id),
         {:role, true} <- {:role, role in [:administrator, :moderator]},
         {:ok, %ActionLog{} = create_action_log} <-
           Admin.create_action_log(%{
             "actor_id" => actor_id,
             "target_type" => to_string(target.__struct__),
             "target_id" => target.id,
             "action" => action,
             "changes" => stringify_struct(target)
           }) do
      {:ok, create_action_log}
    end
  end

  defp stringify_struct(%_{} = struct) do
    association_fields = struct.__struct__.__schema__(:associations)

    struct
    |> Map.from_struct()
    |> Map.drop(association_fields ++ [:__meta__])
  end

  defp stringify_struct(struct), do: struct
end
