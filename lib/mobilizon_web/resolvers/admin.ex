defmodule MobilizonWeb.Resolvers.Admin do
  @moduledoc """
  Handles the report-related GraphQL calls
  """
  alias Mobilizon.Events
  alias Mobilizon.Users.User
  import Mobilizon.Users.Guards
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Reports.{Report, Note}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Statistics

  def list_action_logs(
        _parent,
        %{page: page, limit: limit},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    with action_logs <- Mobilizon.Admin.list_action_logs(page, limit) do
      action_logs =
        action_logs
        |> Enum.map(fn %ActionLog{
                         target_type: target_type,
                         action: action,
                         actor: actor,
                         id: id,
                         inserted_at: inserted_at
                       } = action_log ->
          with data when is_map(data) <-
                 transform_action_log(String.to_existing_atom(target_type), action, action_log) do
            Map.merge(data, %{actor: actor, id: id, inserted_at: inserted_at})
          end
        end)
        |> Enum.filter(& &1)

      {:ok, action_logs}
    end
  end

  def list_action_logs(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and a moderator to list action logs"}
  end

  defp transform_action_log(
         Report,
         :update,
         %ActionLog{} = action_log
       ) do
    with %Report{} = report <- Mobilizon.Reports.get_report(action_log.target_id) do
      action =
        case action_log do
          %ActionLog{changes: %{"status" => "closed"}} -> :report_update_closed
          %ActionLog{changes: %{"status" => "open"}} -> :report_update_opened
          %ActionLog{changes: %{"status" => "resolved"}} -> :report_update_resolved
        end

      %{
        action: action,
        object: report
      }
    end
  end

  defp transform_action_log(Note, :create, %ActionLog{
         changes: changes
       }) do
    %{
      action: :note_creation,
      object: convert_changes_to_struct(Note, changes)
    }
  end

  defp transform_action_log(Note, :delete, %ActionLog{
         changes: changes
       }) do
    %{
      action: :note_deletion,
      object: convert_changes_to_struct(Note, changes)
    }
  end

  defp transform_action_log(Event, :delete, %ActionLog{
         changes: changes
       }) do
    %{
      action: :event_deletion,
      object: convert_changes_to_struct(Event, changes)
    }
  end

  # Changes are stored as %{"key" => "value"} so we need to convert them back as struct
  defp convert_changes_to_struct(struct, %{"report_id" => _report_id} = changes) do
    with data <- for({key, val} <- changes, into: %{}, do: {String.to_atom(key), val}),
         data <- Map.put(data, :report, Mobilizon.Reports.get_report(data.report_id)) do
      struct(struct, data)
    end
  end

  defp convert_changes_to_struct(struct, changes) do
    with data <- for({key, val} <- changes, into: %{}, do: {String.to_atom(key), val}) do
      struct(struct, data)
    end
  end

  def get_dashboard(_parent, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    last_public_event_published =
      case Events.list_events(1, 1, :inserted_at, :desc) do
        [event | _] -> event
        _ -> nil
      end

    {:ok,
     %{
       number_of_users: Statistics.get_cached_value(:local_users),
       number_of_events: Statistics.get_cached_value(:local_events),
       number_of_comments: Statistics.get_cached_value(:local_comments),
       number_of_reports: Mobilizon.Reports.count_opened_reports(),
       last_public_event_published: last_public_event_published
     }}
  end

  def get_dashboard(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and an administrator to access dashboard statistics"}
  end
end
