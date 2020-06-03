defmodule Mobilizon.GraphQL.Resolvers.Admin do
  @moduledoc """
  Handles the report-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Admin, Config, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Admin.{ActionLog, Setting}
  alias Mobilizon.Config
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Service.Statistics
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

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

  defp transform_action_log(Note, :create, %ActionLog{changes: changes}) do
    %{
      action: :note_creation,
      object: convert_changes_to_struct(Note, changes)
    }
  end

  defp transform_action_log(Note, :delete, %ActionLog{changes: changes}) do
    %{
      action: :note_deletion,
      object: convert_changes_to_struct(Note, changes)
    }
  end

  defp transform_action_log(Event, :delete, %ActionLog{changes: changes}) do
    %{
      action: :event_deletion,
      object: convert_changes_to_struct(Event, changes)
    }
  end

  defp transform_action_log(Comment, :delete, %ActionLog{changes: changes}) do
    %{
      action: :comment_deletion,
      object: convert_changes_to_struct(Comment, changes)
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

  def get_dashboard(_parent, _args, %{context: %{current_user: %User{role: role}}})
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

  def get_settings(_parent, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    {:ok,
     %{
       instance_description: Config.instance_description(),
       instance_name: Config.instance_name(),
       registrations_open: Config.instance_registrations_open?(),
       instance_terms: Config.instance_terms(),
       instance_terms_type: Config.instance_terms_type(),
       instance_terms_url: Config.instance_terms_url()
     }}
  end

  def get_settings(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and an administrator to access admin settings"}
  end

  def save_settings(_parent, args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    with {:ok, res} <- Admin.save_settings("instance", args) do
      res =
        res |> Enum.map(fn {key, %Setting{value: value}} -> {key, value} end) |> Enum.into(%{})

      Config.clear_config_cache()

      {:ok, res}
    end
  end

  def save_settings(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and an administrator to save admin settings"}
  end

  def list_relay_followers(
        _parent,
        %{page: page, limit: limit},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    with %Actor{} = relay_actor <- Relay.get_actor() do
      %Page{} =
        page = Actors.list_external_followers_for_actor_paginated(relay_actor, page, limit)

      {:ok, page}
    end
  end

  def list_relay_followings(
        _parent,
        %{page: page, limit: limit},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    with %Actor{} = relay_actor <- Relay.get_actor() do
      %Page{} =
        page = Actors.list_external_followings_for_actor_paginated(relay_actor, page, limit)

      {:ok, page}
    end
  end

  def create_relay(_parent, %{address: address}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Relay.follow(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, {:error, err}} when is_bitstring(err) ->
        {:error, err}
    end
  end

  def remove_relay(_parent, %{address: address}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Relay.unfollow(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, {:error, err}} when is_bitstring(err) ->
        {:error, err}
    end
  end

  def accept_subscription(
        _parent,
        %{address: address},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    case Relay.accept(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, {:error, err}} when is_bitstring(err) ->
        {:error, err}
    end
  end

  def reject_subscription(
        _parent,
        %{address: address},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    case Relay.reject(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, {:error, err}} when is_bitstring(err) ->
        {:error, err}
    end
  end
end
