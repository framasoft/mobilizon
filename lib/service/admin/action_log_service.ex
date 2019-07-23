defmodule Mobilizon.Service.Admin.ActionLogService do
  @moduledoc """
  Module to handle action log creations
  """

  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Admin
  alias Mobilizon.Admin.ActionLog

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
             "changes" => Map.from_struct(target) |> Map.take([:status, :uri, :content])
           }) do
      {:ok, create_action_log}
    end
  end
end
