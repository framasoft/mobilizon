defmodule MobilizonWeb.Resolvers.Admin do
  @moduledoc """
  Handles the report-related GraphQL calls
  """
  alias Mobilizon.Users.User
  import Mobilizon.Users.Guards
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Reports.{Report, Note}

  def list_action_logs(_parent, %{page: page, limit: limit}, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    with action_logs <- Mobilizon.Admin.list_action_logs(page, limit) do
      action_logs =
        Enum.map(action_logs, fn %ActionLog{
                                   target_type: target_type,
                                   action: action,
                                   actor: actor,
                                   id: id
                                 } = action_log ->
          transform_action_log(target_type, action, action_log)
          |> Map.merge(%{
            actor: actor,
            id: id
          })
        end)

      {:ok, action_logs}
    end
  end

  def list_action_logs(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and a moderator to list action logs"}
  end

  defp transform_action_log(
         "Elixir.Mobilizon.Reports.Report",
         "update",
         %ActionLog{} = action_log
       ) do
    with %Report{status: status} = report <- Mobilizon.Reports.get_report(action_log.target_id) do
      %{
        action: "report_update_" <> to_string(status),
        object: report
      }
    end
  end

  defp transform_action_log("Elixir.Mobilizon.Reports.Note", "create", %ActionLog{
         changes: changes
       }) do
    %{
      action: "note_creation",
      object: convert_changes_to_struct(Note, changes)
    }
  end

  defp transform_action_log("Elixir.Mobilizon.Reports.Note", "delete", %ActionLog{
         changes: changes
       }) do
    %{
      action: "note_deletion",
      object: convert_changes_to_struct(Note, changes)
    }
  end

  # Changes are stored as %{"key" => "value"} so we need to convert them back as struct
  defp convert_changes_to_struct(struct, changes) do
    struct(struct, for({key, val} <- changes, into: %{}, do: {String.to_atom(key), val}))
  end
end
