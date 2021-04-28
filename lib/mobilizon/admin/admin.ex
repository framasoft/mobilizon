defmodule Mobilizon.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query
  import EctoEnum

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Admin, Users}
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Admin.Setting
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  defenum(ActionLogAction, [
    "update",
    "create",
    "delete",
    "suspend",
    "unsuspend"
  ])

  alias Ecto.Multi

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
  @spec list_action_logs(integer | nil, integer | nil) :: Page.t()
  def list_action_logs(page \\ nil, limit \\ nil) do
    list_action_logs_query()
    |> Page.build_page(page, limit)
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

  def get_admin_setting_value(group, name, fallback \\ nil)
      when is_binary(group) and is_binary(name) do
    case Repo.get_by(Setting, group: group, name: name) do
      nil ->
        fallback

      %Setting{value: ""} ->
        fallback

      %Setting{value: nil} ->
        fallback

      %Setting{value: value} ->
        get_setting_value(value)
    end
  end

  def get_setting_value(nil), do: nil

  def get_setting_value(value) do
    case Jason.decode(value) do
      {:ok, val} ->
        val

      {:error, _} ->
        case value do
          "true" -> true
          "false" -> false
          value -> value
        end
    end
  end

  def set_admin_setting_value(group, name, value) do
    Setting
    |> Setting.changeset(%{group: group, name: name, value: value})
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:group, :name])
  end

  def save_settings(group, args) do
    Multi.new()
    |> do_save_setting(group, args)
    |> Repo.transaction()
  end

  def clear_settings(group) do
    Setting |> where([s], s.group == ^group) |> Repo.delete_all()
  end

  defp do_save_setting(transaction, _group, args) when args == %{}, do: transaction

  defp do_save_setting(transaction, group, args) do
    key = hd(Map.keys(args))
    {val, rest} = Map.pop(args, key)

    transaction =
      Multi.insert(
        transaction,
        key,
        Setting.changeset(%Setting{}, %{
          group: group,
          name: Atom.to_string(key),
          value: convert_to_string(val)
        }),
        on_conflict: :replace_all,
        conflict_target: [:group, :name]
      )

    do_save_setting(transaction, group, rest)
  end

  defp convert_to_string(val) do
    case val do
      val when is_list(val) -> Jason.encode!(val)
      val -> to_string(val)
    end
  end
end
