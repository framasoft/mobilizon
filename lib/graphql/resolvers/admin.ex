defmodule Mobilizon.GraphQL.Resolvers.Admin do
  @moduledoc """
  Handles the report-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Admin, Config, Events, Instances, Media, Users}
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Admin.{ActionLog, Setting, SettingMedia}
  alias Mobilizon.Cldr.Language
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.{Actions, Relay}
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Service.Statistics
  alias Mobilizon.Service.Workers.RefreshInstances
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email

  alias Mobilizon.GraphQL.Resolvers.Media, as: MediaResolver

  import Mobilizon.Web.Gettext
  require Logger

  @spec list_action_logs(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(ActionLog.t())} | {:error, String.t()}
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
          target_type
          |> String.to_existing_atom()
          |> transform_action_log(action, action_log)
          |> add_extra_data(actor, id, inserted_at)
        end)
        |> Enum.filter(& &1)

      {:ok, %Page{elements: action_logs, total: total}}
    end
  end

  def list_action_logs(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in and a moderator to list action logs")}
  end

  defp add_extra_data(nil, _actor, _id, _inserted_at), do: nil

  defp add_extra_data(map, actor, id, inserted_at) do
    Map.merge(map, %{actor: actor, id: id, inserted_at: inserted_at})
  end

  @spec transform_action_log(module(), atom(), ActionLog.t()) :: map() | nil
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

  defp transform_action_log(_, _, _), do: nil

  # Changes are stored as %{"key" => "value"} so we need to convert them back as struct
  @spec convert_changes_to_struct(module(), map()) :: struct()
  defp convert_changes_to_struct(struct, %{"report_id" => _report_id} = changes) do
    data = for({key, val} <- changes, into: %{}, do: {String.to_existing_atom(key), val})
    data = Map.put(data, :report, Mobilizon.Reports.get_report(data.report_id))
    struct(struct, data)
  end

  defp convert_changes_to_struct(struct, changes) do
    changeset = struct.__changeset__

    data =
      for(
        {key, val} <- changes,
        into: %{},
        do: {String.to_existing_atom(key), process_eventual_type(changeset, key, val)}
      )

    struct(struct, data)
  end

  # datetimes are not unserialized as DateTime/NaiveDateTime so we do it manually with changeset data
  @spec process_eventual_type(Ecto.Changeset.t(), String.t(), String.t() | nil) ::
          DateTime.t() | NaiveDateTime.t() | any()
  defp process_eventual_type(changeset, key, val) do
    cond do
      changeset[String.to_existing_atom(key)] == Mobilizon.Actors.ActorType and not is_nil(val) ->
        String.to_existing_atom(val)

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

  @spec get_list_of_languages(any(), any(), any()) :: {:ok, String.t()} | {:error, any()}
  def get_list_of_languages(_parent, %{codes: codes}, _resolution) when is_list(codes) do
    locale = Mobilizon.Cldr.locale_or_default(Gettext.get_locale())

    case Language.known_languages(String.to_existing_atom(locale)) do
      data when is_map(data) ->
        data
        |> Enum.map(fn {code, elem} ->
          %{code: code, name: Map.get(elem, :standard, "Unknown")}
        end)
        |> Enum.filter(fn %{code: code, name: _name} -> code in codes end)
        |> (&{:ok, &1}).()

      {:error, err} ->
        {:error, err}
    end
  end

  def get_list_of_languages(_parent, _args, _resolution) do
    locale = Gettext.get_locale()

    case Language.known_languages(String.to_existing_atom(locale)) do
      data when is_map(data) ->
        data =
          Enum.map(data, fn {code, elem} ->
            %{code: code, name: Map.get(elem, :standard, "Unknown")}
          end)

        {:ok, data}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec get_dashboard(any(), any(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def get_dashboard(_parent, _args, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    last_public_event_published =
      case Events.list_events(1, 1, :inserted_at, :desc) do
        %Page{elements: [event | _]} -> event
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
       last_group_created: Actors.last_group_created()
     }}
  end

  def get_dashboard(_parent, _args, _resolution) do
    {:error,
     dgettext(
       "errors",
       "You need to be logged-in and an administrator to access dashboard statistics"
     )}
  end

  @spec get_settings(any(), any(), Absinthe.Resolution.t()) :: {:ok, map()} | {:error, String.t()}
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

  @spec save_settings(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def save_settings(_parent, args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    with {:ok, res} <- Admin.save_settings("instance", args),
         res <-
           res
           |> Enum.map(fn {key, val} ->
             case val do
               %Setting{value: value} -> {key, Admin.get_setting_value(value)}
               %SettingMedia{media: media} -> {key, media}
             end
           end)
           |> Enum.into(%{}),
         :ok <- eventually_update_instance_actor(res) do
      Config.clear_config_cache()

      {:ok, res}
    end
  end

  def save_settings(_parent, _args, _resolution) do
    {:error,
     dgettext("errors", "You need to be logged-in and an administrator to save admin settings")}
  end

  @spec get_media_setting(any(), any(), Absinthe.Resolution.t()) ::
          {:ok, Media.t()} | {:error, String.t()}
  def get_media_setting(_parent, %{group: group, name: name}, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    {:ok, MediaResolver.transform_media(Admin.get_admin_setting_media(group, name, nil))}
  end

  def get_media_setting(_parent, _args, _resolution) do
    {:error,
     dgettext("errors", "You need to be logged-in and an administrator to access admin settings")}
  end

  @spec get_instance_logo(any(), any(), Absinthe.Resolution.t()) ::
          {:ok, Media.t() | nil} | {:error, String.t()}
  def get_instance_logo(parent, _args, resolution) do
    get_media_setting(parent, %{group: "instance", name: "instance_logo"}, resolution)
  end

  @spec get_instance_favicon(any(), any(), Absinthe.Resolution.t()) ::
          {:ok, Media.t() | nil} | {:error, String.t()}
  def get_instance_favicon(parent, _args, resolution) do
    get_media_setting(parent, %{group: "instance", name: "instance_favicon"}, resolution)
  end

  @spec get_default_picture(any(), any(), Absinthe.Resolution.t()) ::
          {:ok, Media.t() | nil} | {:error, String.t()}
  def get_default_picture(parent, _args, resolution) do
    get_media_setting(parent, %{group: "instance", name: "default_picture"}, resolution)
  end

  @spec update_user(any, map(), Absinthe.Resolution.t()) ::
          {:error, :invalid_argument | :user_not_found | binary | Ecto.Changeset.t()}
          | {:ok, Mobilizon.Users.User.t()}
  def update_user(_parent, %{id: id, notify: notify} = args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    case Users.get_user(id) do
      nil ->
        {:error, :user_not_found}

      %User{} = user ->
        case args |> Map.drop([:notify, :id]) |> Map.keys() do
          [] ->
            {:error, :invalid_argument}

          [change | _] ->
            case change do
              :email -> change_email(user, Map.get(args, :email), notify)
              :role -> change_role(user, Map.get(args, :role), notify)
              :confirmed -> confirm_user(user, Map.get(args, :confirmed), notify)
            end
        end
    end
  end

  def update_user(_parent, _args, _resolution) do
    {:error,
     dgettext("errors", "You need to be logged-in and an administrator to edit an user's details")}
  end

  @spec change_email(User.t(), String.t(), boolean()) :: {:ok, User.t()} | {:error, String.t()}
  defp change_email(%User{email: old_email} = user, new_email, notify) do
    if Authenticator.can_change_email?(user) do
      if new_email != old_email do
        do_change_email_different(user, old_email, new_email, notify)
      else
        {:error, dgettext("errors", "The new email must be different")}
      end
    end
  end

  @spec do_change_email_different(User.t(), String.t(), String.t(), boolean()) ::
          {:ok, User.t()} | {:error, String.t()}
  defp do_change_email_different(user, old_email, new_email, notify) do
    if Email.Checker.valid?(new_email) do
      do_change_email(user, old_email, new_email, notify)
    else
      {:error, dgettext("errors", "The new email doesn't seem to be valid")}
    end
  end

  @spec do_change_email(User.t(), String.t(), String.t(), boolean()) ::
          {:ok, User.t()} | {:error, String.t()}
  defp do_change_email(user, old_email, new_email, notify) do
    case Users.update_user(user, %{email: new_email}) do
      {:ok, %User{} = updated_user} ->
        if notify do
          updated_user
          |> Email.Admin.user_email_change_old(old_email)
          |> Email.Mailer.send_email()

          updated_user
          |> Email.Admin.user_email_change_new(old_email)
          |> Email.Mailer.send_email()
        end

        {:ok, updated_user}

      {:error, %Ecto.Changeset{} = err} ->
        Logger.debug(inspect(err))
        {:error, dgettext("errors", "Failed to update user email")}
    end
  end

  @spec change_role(User.t(), atom(), boolean()) ::
          {:ok, User.t()} | {:error, String.t() | Ecto.Changeset.t()}
  defp change_role(%User{role: old_role} = user, new_role, notify) do
    if old_role != new_role do
      with {:ok, %User{} = user} <- Users.update_user(user, %{role: new_role}) do
        if notify do
          user
          |> Email.Admin.user_role_change(old_role)
          |> Email.Mailer.send_email()
        end

        {:ok, user}
      end
    else
      {:error, dgettext("errors", "The new role must be different")}
    end
  end

  @spec confirm_user(User.t(), boolean(), boolean()) ::
          {:ok, User.t()} | {:error, String.t() | Ecto.Changeset.t()}
  defp confirm_user(%User{confirmed_at: nil} = user, true, notify) do
    with {:ok, %User{} = user} <-
           Users.update_user(user, %{
             confirmed_at: DateTime.utc_now(),
             confirmation_sent_at: nil,
             confirmation_token: nil
           }) do
      if notify do
        user
        |> Email.Admin.user_confirmation()
        |> Email.Mailer.send_email()
      end

      {:ok, user}
    end
  end

  defp confirm_user(%User{confirmed_at: %DateTime{}} = _user, true, _notify) do
    {:error, dgettext("errors", "Can't confirm an already confirmed user")}
  end

  defp confirm_user(_user, _confirm, _notify) do
    {:error, dgettext("errors", "Deconfirming users is not supported")}
  end

  @spec list_relay_followers(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Follower.t())} | {:error, :unauthorized | :unauthenticated}
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

  @spec list_relay_followings(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Follower.t())} | {:error, :unauthorized | :unauthenticated}
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

  def get_instances(
        _parent,
        args,
        %{
          context: %{current_user: %User{role: role}}
        }
      )
      when is_admin(role) do
    {:ok,
     Instances.instances(
       args
       |> Keyword.new()
       |> Keyword.take([
         :page,
         :limit,
         :order_by,
         :direction,
         :filter_domain,
         :filter_follow_status,
         :filter_suspend_status
       ])
     )}
  end

  def get_instances(_parent, _args, %{context: %{current_user: %User{}}}) do
    {:error, :unauthorized}
  end

  def get_instances(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @spec get_instance(any, map(), Absinthe.Resolution.t()) ::
          {:error, :unauthenticated | :unauthorized | :not_found}
          | {:ok, Mobilizon.Instances.Instance.t()}
  def get_instance(_parent, %{domain: domain}, %{
        context: %{current_user: %User{role: role}}
      })
      when is_admin(role) do
    remote_relay = Instances.get_instance_actor(domain)
    local_relay = Relay.get_actor()

    result =
      if is_nil(remote_relay) do
        %{
          has_relay: false,
          relay_address: nil,
          follower_status: nil,
          followed_status: nil,
          software: nil,
          software_version: nil
        }
      else
        %{
          has_relay: !is_nil(remote_relay.actor),
          relay_address:
            if(is_nil(remote_relay.actor),
              do: nil,
              else: Actor.preferred_username_and_domain(remote_relay.actor)
            ),
          follower_status: follow_status(remote_relay.actor, local_relay),
          followed_status: follow_status(local_relay, remote_relay.actor),
          instance_name: remote_relay.instance_name,
          instance_description: remote_relay.instance_description,
          software: remote_relay.software,
          software_version: remote_relay.software_version
        }
      end

    case Instances.instance(domain) do
      nil -> {:error, :not_found}
      instance -> {:ok, Map.merge(instance, result)}
    end
  end

  def get_instance(_parent, _args, %{context: %{current_user: %User{}}}) do
    {:error, :unauthorized}
  end

  def get_instance(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @spec create_instance(any, map(), Absinthe.Resolution.t()) ::
          {:error, atom() | binary()}
          | {:ok, Mobilizon.Instances.Instance.t()}
  def create_instance(
        parent,
        %{domain: domain} = args,
        %{context: %{current_user: %User{role: role}}} = resolution
      )
      when is_admin(role) do
    case Relay.follow(domain) do
      {:ok, _activity, _follow} ->
        Instances.refresh()
        RefreshInstances.refresh_instance_actor(domain)
        get_instance(parent, args, resolution)

      {:error, :follow_pending} ->
        {:error, dgettext("errors", "This instance is pending follow approval")}

      {:error, :already_following} ->
        {:error, dgettext("errors", "You are already following this instance")}

      {:error, :http_error} ->
        {:error, dgettext("errors", "Unable to find an instance to follow at this address")}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec remove_relay(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Follower.t()} | {:error, any()}
  def remove_relay(_parent, %{address: address}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    with {:ok, _activity, follow} <- Relay.unfollow(address) do
      {:ok, follow}
    end
  end

  @spec accept_subscription(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Follower.t()} | {:error, any()}
  def accept_subscription(
        _parent,
        %{address: address},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    with {:ok, _activity, follow} <- Relay.accept(address) do
      {:ok, follow}
    end
  end

  @spec reject_subscription(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Follower.t()} | {:error, any()}
  def reject_subscription(
        _parent,
        %{address: address},
        %{context: %{current_user: %User{role: role}}}
      )
      when is_admin(role) do
    with {:ok, _activity, follow} <- Relay.reject(address) do
      {:ok, follow}
    end
  end

  @spec eventually_update_instance_actor(map()) :: :ok | {:error, :instance_actor_update_failure}
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

    if args != %{} do
      %Actor{} = instance_actor = Relay.get_actor()

      case Actions.Update.update(instance_actor, args, true) do
        {:ok, _activity, _actor} ->
          :ok

        {:error, _err} ->
          {:error, :instance_actor_update_failure}
      end
    else
      :ok
    end
  end

  @spec follow_status(Actor.t() | nil, Actor.t() | nil) :: :approved | :pending | :none
  defp follow_status(follower, followed) when follower != nil and followed != nil do
    case Actors.check_follow(follower, followed) do
      %Follower{approved: true} -> :approved
      %Follower{approved: false} -> :pending
      _ -> :none
    end
  end

  defp follow_status(_, _), do: :none
end
