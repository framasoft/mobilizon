defmodule Mobilizon.GraphQL.Resolvers.Admin do
  @moduledoc """
  Handles the report-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Admin, Config, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Admin.{ActionLog, Setting}
  alias Mobilizon.Cldr.Language
  alias Mobilizon.Config
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Service.Statistics
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext
  require Logger

  def list_action_logs(
        _parent,
        %{page: page, limit: limit},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    with %Page{elements: action_logs, total: total} <-
           Mobilizon.Admin.list_action_logs(page, limit) do
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

      {:ok, %Page{elements: action_logs, total: total}}
    end
  end

  def list_action_logs(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to list action logs")}
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

  defp transform_action_log(Actor, :suspend, %ActionLog{changes: changes}) do
    %{
      action: :actor_suspension,
      object: convert_changes_to_struct(Actor, changes)
    }
  end

  defp transform_action_log(Actor, :unsuspend, %ActionLog{changes: changes}) do
    %{
      action: :actor_unsuspension,
      object: convert_changes_to_struct(Actor, changes)
    }
  end

  defp transform_action_log(User, :delete, %ActionLog{changes: changes}) do
    %{
      action: :user_deletion,
      object: convert_changes_to_struct(User, changes)
    }
  end

  # Changes are stored as %{"key" => "value"} so we need to convert them back as struct
  defp convert_changes_to_struct(struct, %{"report_id" => _report_id} = changes) do
    with data <- for({key, val} <- changes, into: %{}, do: {String.to_existing_atom(key), val}),
         data <- Map.put(data, :report, Mobilizon.Reports.get_report(data.report_id)) do
      struct(struct, data)
    end
  end

  defp convert_changes_to_struct(struct, changes) do
    with changeset <- struct.__changeset__,
         data <-
           for(
             {key, val} <- changes,
             into: %{},
             do: {String.to_existing_atom(key), process_eventual_type(changeset, key, val)}
           ) do
      struct(struct, data)
    end
  end

  # datetimes are not unserialized as DateTime/NaiveDateTime so we do it manually with changeset data
  defp process_eventual_type(changeset, key, val) do
    cond do
      changeset[String.to_existing_atom(key)] == :utc_datetime and not is_nil(val) ->
        {:ok, datetime, _} = DateTime.from_iso8601(val)
        datetime

      changeset[String.to_existing_atom(key)] == :naive_datetime and not is_nil(val) ->
        {:ok, datetime} = NaiveDateTime.from_iso8601(val)
        datetime

      true ->
        val
    end
  end

  def get_list_of_languages(_parent, %{codes: codes}, _resolution) when is_list(codes) do
    locale = Gettext.get_locale()
    locale = if Cldr.known_locale_name?(locale), do: locale, else: "en"

    case Language.known_languages(locale) do
      data when is_map(data) ->
        data
        |> Enum.map(fn {code, elem} -> %{code: code, name: elem.standard} end)
        |> Enum.filter(fn %{code: code, name: _name} -> code in codes end)
        |> (&{:ok, &1}).()

      {:error, err} ->
        {:error, err}
    end
  end

  def get_list_of_languages(_parent, _args, _resolution) do
    locale = Gettext.get_locale()

    case Language.known_languages(locale) do
      data when is_map(data) ->
        data = Enum.map(data, fn {code, elem} -> %{code: code, name: elem.standard} end)
        {:ok, data}

      {:error, err} ->
        {:error, err}
    end
  end

  def get_dashboard(_parent, _args, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    last_public_event_published =
      case Events.list_events(1, 1, :inserted_at, :desc) do
        %Page{elements: [event | _]} -> event
        _ -> nil
      end

    last_group_created =
      case Actors.list_actors(:Group) do
        %Page{elements: [group | _]} -> group
        _ -> nil
      end

    {:ok,
     %{
       number_of_users: Statistics.get_cached_value(:local_users),
       number_of_events: Statistics.get_cached_value(:local_events),
       number_of_groups: Statistics.get_cached_value(:local_groups),
       number_of_comments: Statistics.get_cached_value(:local_comments),
       number_of_confirmed_participations_to_local_events:
         Statistics.get_cached_value(:confirmed_participations_to_local_events),
       number_of_reports: Mobilizon.Reports.count_opened_reports(),
       number_of_followers: Statistics.get_cached_value(:instance_followers),
       number_of_followings: Statistics.get_cached_value(:instance_followings),
       last_public_event_published: last_public_event_published,
       last_group_created: last_group_created
     }}
  end

  def get_dashboard(_parent, _args, _resolution) do
    {:error,
     dgettext(
       "errors",
       "You need to be logged-in and an administrator to access dashboard statistics"
     )}
  end

  def get_settings(_parent, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    {:ok, Config.admin_settings()}
  end

  def get_settings(_parent, _args, _resolution) do
    {:error,
     dgettext("errors", "You need to be logged-in and an administrator to access admin settings")}
  end

  def save_settings(_parent, args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    with {:ok, res} <- Admin.save_settings("instance", args),
         res <-
           res
           |> Enum.map(fn {key, %Setting{value: value}} ->
             {key, Admin.get_setting_value(value)}
           end)
           |> Enum.into(%{}),
         :ok <- eventually_update_instance_actor(res) do
      Config.clear_config_cache()
      Cachex.put(:config, :admin_config, res)

      {:ok, res}
    end
  end

  def save_settings(_parent, _args, _resolution) do
    {:error,
     dgettext("errors", "You need to be logged-in and an administrator to save admin settings")}
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

  def list_relay_followers(_parent, _args, %{context: %{current_user: %User{}}}) do
    {:error, :unauthorized}
  end

  def list_relay_followers(_parent, _args, _resolution) do
    {:error, :unauthenticated}
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

  def list_relay_followings(_parent, _args, %{context: %{current_user: %User{}}}) do
    {:error, :unauthorized}
  end

  def list_relay_followings(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  def create_relay(_parent, %{address: address}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Relay.follow(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, err} when is_binary(err) ->
        {:error, err}
    end
  end

  def remove_relay(_parent, %{address: address}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Relay.unfollow(address) do
      {:ok, _activity, follow} ->
        {:ok, follow}

      {:error, {:error, err}} when is_binary(err) ->
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

      {:error, {:error, err}} when is_binary(err) ->
        {:error, err}

      {:error, err} when is_binary(err) ->
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

      {:error, {:error, err}} when is_binary(err) ->
        {:error, err}

      {:error, err} when is_binary(err) ->
        {:error, err}
    end
  end

  @spec eventually_update_instance_actor(map()) :: :ok
  defp eventually_update_instance_actor(admin_setting_args) do
    args = %{}
    new_instance_description = Map.get(admin_setting_args, :instance_description)
    new_instance_name = Map.get(admin_setting_args, :instance_name)

    %{
      instance_description: old_instance_description,
      instance_name: old_instance_name
    } = Config.admin_settings()

    args =
      if not is_nil(new_instance_description) &&
           new_instance_description != old_instance_description,
         do: Map.put(args, :summary, new_instance_description),
         else: args

    args =
      if not is_nil(new_instance_name) && new_instance_name != old_instance_name,
        do: Map.put(args, :name, new_instance_name),
        else: args

    with {:changes, true} <- {:changes, args != %{}},
         %Actor{} = instance_actor <- Relay.get_actor(),
         {:ok, _activity, _actor} <- ActivityPub.update(instance_actor, args, true) do
      :ok
    else
      {:changes, false} ->
        :ok

      err ->
        err
    end
  end
end
