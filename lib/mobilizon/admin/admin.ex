defmodule Mobilizon.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query
  import EctoEnum

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Admin, Users}
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  defenum(ActionLogAction, [
    "update",
    "create",
    "delete"
  ])

  @doc """
  Creates a action_log.
  """
  @spec create_action_log(map) :: {:ok, ActionLog.t()} | {:error, Ecto.Changeset.t()}
  def create_action_log(attrs \\ %{}) do
    %ActionLog{}
    |> ActionLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of action logs.
  """
  @spec list_action_logs(integer | nil, integer | nil) :: [ActionLog.t()]
  def list_action_logs(page \\ nil, limit \\ nil) do
    list_action_logs_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

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

  @spec list_action_logs_query :: Ecto.Query.t()
  defp list_action_logs_query do
    from(r in ActionLog, preload: [:actor], order_by: [desc: :id])
  end

  defp stringify_struct(%_{} = struct) do
    association_fields = struct.__struct__.__schema__(:associations)

    struct
    |> Map.from_struct()
    |> Map.drop(association_fields ++ [:__meta__])
  end

  defp stringify_struct(struct), do: struct
end
