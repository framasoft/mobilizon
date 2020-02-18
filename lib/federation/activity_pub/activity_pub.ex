# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub.ex

defmodule Mobilizon.Federation.ActivityPub do
  @moduledoc """
  The ActivityPub context.
  """

  import Mobilizon.Federation.ActivityPub.Utils

  alias Mobilizon.{
    Actors,
    Config,
    Conversations,
    Events,
    Reports,
    Resources,
    Share,
    Todos,
    Users
  }

  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Reports.Report
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}
  alias Mobilizon.Tombstone

  alias Mobilizon.Federation.ActivityPub.{
    Activity,
    Audience,
    Federator,
    Relay,
    Transmogrifier,
    Visibility
  }

  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Utils, as: ConverterUtils
  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Federation.WebFinger

  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Service.RichMedia.Parser

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Email.{Admin, Mailer}

  require Logger

  @doc """
  Wraps an object into an activity
  """
  @spec create_activity(map(), boolean()) :: {:ok, Activity.t()}
  def create_activity(map, local \\ true) when is_map(map) do
    with map <- lazy_put_activity_defaults(map) do
      {:ok,
       %Activity{
         data: map,
         local: local,
         actor: map["actor"],
         recipients: get_recipients(map)
       }}
    end
  end

  @doc """
  Fetch an object from an URL, from our local database of events and comments, then eventually remote
  """
  # TODO: Make database calls parallel
  @spec fetch_object_from_url(String.t()) :: {:ok, %Event{}} | {:ok, %Comment{}} | {:error, any()}
  def fetch_object_from_url(url) do
    Logger.info("Fetching object from url #{url}")

    with {:not_http, true} <- {:not_http, String.starts_with?(url, "http")},
         {:existing_event, nil} <- {:existing_event, Events.get_event_by_url(url)},
         {:existing_comment, nil} <- {:existing_comment, Conversations.get_comment_from_url(url)},
         {:existing_resource, nil} <- {:existing_resource, Resources.get_resource_by_url(url)},
         {:existing_actor, {:error, :actor_not_found}} <-
           {:existing_actor, Actors.get_actor_by_url(url)},
         date <- Signature.generate_date_header(),
         headers <-
           [{:Accept, "application/activity+json"}]
           |> maybe_date_fetch(date)
           |> sign_fetch_relay(url, date),
         {:ok, %HTTPoison.Response{body: body, status_code: code}} when code in 200..299 <-
           HTTPoison.get(
             url,
             headers,
             follow_redirect: true,
             timeout: 10_000,
             recv_timeout: 20_000,
             ssl: [{:versions, [:"tlsv1.2"]}]
           ),
         {:ok, data} <- Jason.decode(body),
         {:origin_check, true} <- {:origin_check, origin_check?(url, data)},
         params <- %{
           "type" => "Create",
           "to" => data["to"],
           "cc" => data["cc"],
           "actor" => data["attributedTo"],
           "object" => data
         },
         {:ok, _activity, %{url: object_url} = _object} <- Transmogrifier.handle_incoming(params) do
      case data["type"] do
        "Event" ->
          {:ok, Events.get_public_event_by_url_with_preload!(object_url)}

        "Note" ->
          {:ok, Conversations.get_comment_from_url_with_preload!(object_url)}

        "Document" ->
          {:ok, Resources.get_resource_by_url_with_preloads(object_url)}

        "ResourceCollection" ->
          {:ok, Resources.get_resource_by_url_with_preloads(object_url)}

        "Actor" ->
          {:ok, Actors.get_actor_by_url!(object_url, true)}

        other ->
          {:error, other}
      end
    else
      {:existing_event, %Event{url: event_url}} ->
        {:ok, Events.get_public_event_by_url_with_preload!(event_url)}

      {:existing_comment, %Comment{url: comment_url}} ->
        {:ok, Conversations.get_comment_from_url_with_preload!(comment_url)}

      {:existing_resource, %Resource{url: resource_url}} ->
        {:ok, Resources.get_resource_by_url_with_preloads(resource_url)}

      {:existing_actor, {:ok, %Actor{url: actor_url}}} ->
        {:ok, Actors.get_actor_by_url!(actor_url, true)}

      {:origin_check, false} ->
        Logger.warn("Object origin check failed")
        {:error, "Object origin check failed"}

      e ->
        Logger.warn("Something failed while fetching url #{inspect(e)}")
        {:error, e}
    end
  end

  @doc """
  Getting an actor from url, eventually creating it if we don't have it locally or if it needs an update
  """
  @spec get_or_fetch_actor_by_url(String.t(), boolean) :: {:ok, Actor.t()} | {:error, String.t()}
  def get_or_fetch_actor_by_url(url, preload \\ false)

  def get_or_fetch_actor_by_url(nil, _preload), do: {:error, "Can't fetch a nil url"}

  def get_or_fetch_actor_by_url("https://www.w3.org/ns/activitystreams#Public", _preload) do
    with %Actor{url: url} <- Relay.get_actor() do
      get_or_fetch_actor_by_url(url)
    end
  end

  def get_or_fetch_actor_by_url(url, preload) do
    with {:ok, %Actor{} = cached_actor} <- Actors.get_actor_by_url(url, preload),
         false <- Actors.needs_update?(cached_actor) do
      {:ok, cached_actor}
    else
      _ ->
        # For tests, see https://github.com/jjh42/mock#not-supported---mocking-internal-function-calls and Mobilizon.Federation.ActivityPubTest
        case __MODULE__.make_actor_from_url(url, preload) do
          {:ok, %Actor{} = actor} ->
            {:ok, actor}

          err ->
            Logger.warn("Could not fetch by AP id")
            Logger.debug(inspect(err))
            {:error, "Could not fetch by AP id"}
        end
    end
  end

  @doc """
  Create an activity of type `Create`

  * Creates the object, which returns AS data
  * Wraps ActivityStreams data into a `Create` activity
  * Creates an `Mobilizon.Federation.ActivityPub.Activity` from this
  * Federates (asynchronously) the activity
  * Returns the activity
  """
  @spec create(atom(), map(), boolean, map()) :: {:ok, Activity.t(), struct()} | any()
  def create(type, args, local \\ false, additional \\ %{}) do
    Logger.debug("creating an activity")
    Logger.debug(inspect(args))

    with {:tombstone, nil} <- {:tombstone, check_for_tombstones(args)},
         {:ok, entity, create_data} <-
           (case type do
              :event -> create_event(args, additional)
              :comment -> create_comment(args, additional)
              :group -> create_group(args, additional)
              :todo_list -> create_todo_list(args, additional)
              :todo -> create_todo(args, additional)
              :resource -> create_resource(args, additional)
            end),
         {:ok, activity} <- create_activity(create_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, entity}
    else
      err ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @doc """
  Create an activity of type `Update`

  * Updates the object, which returns AS data
  * Wraps ActivityStreams data into a `Update` activity
  * Creates an `Mobilizon.Federation.ActivityPub.Activity` from this
  * Federates (asynchronously) the activity
  * Returns the activity
  """
  @spec update(atom(), struct(), map(), boolean, map()) :: {:ok, Activity.t(), struct()} | any()
  def update(type, old_entity, args, local \\ false, additional \\ %{}) do
    Logger.debug("updating an activity")
    Logger.debug(inspect(args))

    with {:ok, entity, update_data} <-
           (case type do
              :event -> update_event(old_entity, args, additional)
              :comment -> update_comment(old_entity, args, additional)
              :actor -> update_actor(old_entity, args, additional)
              :todo -> update_todo(old_entity, args, additional)
              :resource -> update_resource(old_entity, args, additional)
            end),
         {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, entity}
    else
      err ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        err
    end
  end

  def accept(type, entity, local \\ true, additional \\ %{}) do
    Logger.debug("We're accepting something")

    {:ok, entity, update_data} =
      case type do
        :join -> accept_join(entity, additional)
        :follow -> accept_follow(entity, additional)
        :invite -> accept_invite(entity, additional)
      end

    with {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, entity}
    else
      err ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        err
    end
  end

  def reject(type, entity, local \\ true, additional \\ %{}) do
    {:ok, entity, update_data} =
      case type do
        :join -> reject_join(entity, additional)
        :follow -> reject_follow(entity, additional)
      end

    with {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, entity}
    else
      err ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        err
    end
  end

  def announce(
        %Actor{} = actor,
        object,
        activity_id \\ nil,
        local \\ true,
        public \\ true
      ) do
    with {:ok, %Actor{id: object_owner_actor_id}} <- Actors.get_actor_by_url(object["actor"]),
         {:ok, %Share{} = _share} <- Share.create(object["id"], actor.id, object_owner_actor_id),
         announce_data <- make_announce_data(actor, object, activity_id, public),
         {:ok, activity} <- create_activity(announce_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, object}
    else
      error ->
        {:error, error}
    end
  end

  def unannounce(
        %Actor{} = actor,
        object,
        activity_id \\ nil,
        cancelled_activity_id \\ nil,
        local \\ true
      ) do
    with announce_activity <- make_announce_data(actor, object, cancelled_activity_id),
         unannounce_data <- make_unannounce_data(actor, announce_activity, activity_id),
         {:ok, unannounce_activity} <- create_activity(unannounce_data, local),
         :ok <- maybe_federate(unannounce_activity) do
      {:ok, unannounce_activity, object}
    else
      _e -> {:ok, object}
    end
  end

  @doc """
  Make an actor follow another
  """
  def follow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{} = follower} <-
           Actors.follow(followed, follower, activity_id, false),
         follower_as_data <- Convertible.model_to_as(follower),
         {:ok, activity} <- create_activity(follower_as_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, follower}
    else
      {:error, err, msg} when err in [:already_following, :suspended] ->
        {:error, msg}
    end
  end

  @doc """
  Make an actor unfollow another
  """
  @spec unfollow(Actor.t(), Actor.t(), String.t(), boolean()) :: {:ok, map()} | any()
  def unfollow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{id: follow_id} = follow} <- Actors.unfollow(followed, follower),
         # We recreate the follow activity
         follow_as_data <-
           Convertible.model_to_as(%{follow | actor: follower, target_actor: followed}),
         {:ok, follow_activity} <- create_activity(follow_as_data, local),
         activity_unfollow_id <-
           activity_id || "#{Endpoint.url()}/unfollow/#{follow_id}/activity",
         unfollow_data <-
           make_unfollow_data(follower, followed, follow_activity, activity_unfollow_id),
         {:ok, activity} <- create_activity(unfollow_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, follow}
    else
      err ->
        Logger.debug("Error while unfollowing an actor #{inspect(err)}")
        err
    end
  end

  def delete(object, local \\ true)

  @spec delete(Event.t(), boolean) :: {:ok, Activity.t(), Event.t()}
  def delete(%Event{url: url, organizer_actor: actor} = event, local) do
    data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => url,
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"],
      "id" => url <> "/delete"
    }

    with audience <-
           Audience.calculate_to_and_cc_from_mentions(event),
         {:ok, %Event{} = event} <- Events.delete_event(event),
         {:ok, true} <- Cachex.del(:activity_pub, "event_#{event.uuid}"),
         {:ok, %Tombstone{} = _tombstone} <-
           Tombstone.create_tombstone(%{uri: event.url, actor_id: actor.id}),
         Share.delete_all_by_uri(event.url),
         :ok <- check_for_actor_key_rotation(actor),
         {:ok, activity} <- create_activity(Map.merge(data, audience), local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, event}
    end
  end

  @spec delete(Comment.t(), boolean) :: {:ok, Activity.t(), Comment.t()}
  def delete(%Comment{url: url, actor: actor} = comment, local) do
    data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => url,
      "id" => url <> "/delete",
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with audience <-
           Audience.calculate_to_and_cc_from_mentions(comment),
         {:ok, %Comment{} = comment} <- Conversations.delete_comment(comment),
         {:ok, true} <- Cachex.del(:activity_pub, "comment_#{comment.uuid}"),
         {:ok, %Tombstone{} = _tombstone} <-
           Tombstone.create_tombstone(%{uri: comment.url, actor_id: actor.id}),
         Share.delete_all_by_uri(comment.url),
         :ok <- check_for_actor_key_rotation(actor),
         {:ok, activity} <- create_activity(Map.merge(data, audience), local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, comment}
    end
  end

  def delete(%Actor{url: url} = actor, local) do
    data = %{
      "type" => "Delete",
      "actor" => url,
      "object" => url,
      "id" => url <> "/delete",
      "to" => [url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with {:ok, %Oban.Job{}} <- Actors.delete_actor(actor),
         {:ok, activity} <- create_activity(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, actor}
    end
  end

  def delete(
        %Resource{url: url, actor: %Actor{url: actor_url}} = resource,
        local
      ) do
    Logger.debug("Building Delete Resource activity")

    data = %{
      "actor" => actor_url,
      "type" => "Delete",
      "object" => url,
      "id" => url <> "/delete",
      "to" => [actor_url]
    }

    Logger.debug(inspect(data))

    with {:ok, _resource} <- Resources.delete_resource(resource),
         {:ok, true} <- Cachex.del(:activity_pub, "resource_#{resource.id}"),
         {:ok, activity} <- create_activity(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, resource}
    end
  end

  def flag(args, local \\ false, _additional \\ %{}) do
    with {:build_args, args} <- {:build_args, prepare_args_for_report(args)},
         {:create_report, {:ok, %Report{} = report}} <-
           {:create_report, Reports.create_report(args)},
         report_as_data <- Convertible.model_to_as(report),
         cc <- if(local, do: [report.reported.url], else: []),
         report_as_data <- Map.merge(report_as_data, %{"to" => [], "cc" => cc}),
         {:ok, activity} <- create_activity(report_as_data, local),
         :ok <- maybe_federate(activity) do
      Enum.each(Users.list_moderators(), fn moderator ->
        moderator
        |> Admin.report(report)
        |> Mailer.deliver_later()
      end)

      {:ok, activity, report}
    else
      err ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        err
    end
  end

  def join(object, actor, local \\ true, additional \\ %{})

  def join(%Event{} = event, %Actor{} = actor, local, additional) do
    # TODO Refactor me for federation
    with {:maximum_attendee_capacity, true} <-
           {:maximum_attendee_capacity, check_attendee_capacity(event)},
         role <-
           additional
           |> Map.get(:metadata, %{})
           |> Map.get(:role, Mobilizon.Events.get_default_participant_role(event)),
         {:ok, %Participant{} = participant} <-
           Mobilizon.Events.create_participant(%{
             role: role,
             event_id: event.id,
             actor_id: actor.id,
             url: Map.get(additional, :url),
             metadata:
               additional
               |> Map.get(:metadata, %{})
               |> Map.update(:message, nil, &String.trim(HtmlSanitizeEx.strip_tags(&1)))
           }),
         join_data <- Convertible.model_to_as(participant),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(participant),
         {:ok, activity} <- create_activity(Map.merge(join_data, audience), local),
         :ok <- maybe_federate(activity) do
      if event.local && Mobilizon.Events.get_default_participant_role(event) === :participant &&
           role == :participant do
        accept(
          :join,
          participant,
          true,
          %{"actor" => event.organizer_actor.url}
        )
      else
        {:ok, activity, participant}
      end
    end
  end

  # TODO: Implement me
  def join(%Actor{type: :Group} = _group, %Actor{} = _actor, _local, _additional) do
    :error
  end

  defp check_attendee_capacity(%Event{options: options} = event) do
    with maximum_attendee_capacity <-
           Map.get(options, :maximum_attendee_capacity) || 0 do
      maximum_attendee_capacity == 0 ||
        Mobilizon.Events.count_participant_participants(event.id) < maximum_attendee_capacity
    end
  end

  def leave(object, actor, local \\ true, additional \\ %{})

  # TODO: If we want to use this for exclusion we need to have an extra field
  # for the actor that excluded the participant
  def leave(
        %Event{id: event_id, url: event_url} = _event,
        %Actor{id: actor_id, url: actor_url} = _actor,
        local,
        additional
      ) do
    with {:only_organizer, false} <-
           {:only_organizer, Participant.is_not_only_organizer(event_id, actor_id)},
         {:ok, %Participant{} = participant} <-
           Mobilizon.Events.get_participant(
             event_id,
             actor_id,
             Map.get(additional, :metadata, %{})
           ),
         {:ok, %Participant{} = participant} <-
           Events.delete_participant(participant),
         leave_data <- %{
           "type" => "Leave",
           # If it's an exclusion it should be something else
           "actor" => actor_url,
           "object" => event_url,
           "id" => "#{Endpoint.url()}/leave/event/#{participant.id}"
         },
         audience <-
           Audience.calculate_to_and_cc_from_mentions(participant),
         {:ok, activity} <- create_activity(Map.merge(leave_data, audience), local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, participant}
    end
  end

  @spec invite(Actor.t(), Actor.t(), Actor.t(), boolean, map()) ::
          {:ok, map(), Member.t()} | {:error, :member_not_found}
  def invite(
        %Actor{url: group_url, id: group_id} = group,
        %Actor{url: actor_url, id: actor_id} = actor,
        %Actor{url: target_actor_url, id: target_actor_id} = _target_actor,
        local \\ true,
        additional \\ %{}
      ) do
    Logger.debug("Handling #{actor_url} invite to #{group_url} sent to #{target_actor_url}")

    with {:is_able_to_invite, true} <- {:is_able_to_invite, is_able_to_invite(actor, group)},
         {:ok, %Member{url: member_url} = member} <-
           Actors.create_member(%{
             parent_id: group_id,
             actor_id: target_actor_id,
             role: :invited,
             invited_by_id: actor_id,
             url: Map.get(additional, :url)
           }),
         invite_data <- %{
           "type" => "Invite",
           "actor" => actor_url,
           "object" => group_url,
           "target" => target_actor_url,
           "id" => member_url
         },
         {:ok, activity} <-
           create_activity(
             invite_data
             |> Map.merge(%{"to" => [target_actor_url], "cc" => [group_url]})
             |> Map.merge(additional),
             local
           ),
         :ok <- maybe_federate(activity) do
      {:ok, activity, member}
    end
  end

  defp is_able_to_invite(%Actor{domain: actor_domain, id: actor_id}, %Actor{
         domain: group_domain,
         id: group_id
       }) do
    # If the actor comes from the same domain we trust it
    if actor_domain == group_domain do
      true
    else
      # If local group, we'll send the invite
      with {:ok, %Member{} = admin_member} <- Actors.get_member(actor_id, group_id) do
        Member.is_administrator(admin_member)
      end
    end
  end

  def move(type, old_entity, args, local \\ false, additional \\ %{}) do
    Logger.debug("We're moving something")
    Logger.debug(inspect(args))

    with {:ok, entity, update_data} <-
           (case type do
              :resource -> move_resource(old_entity, args, additional)
            end),
         {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, entity}
    else
      err ->
        Logger.error("Something went wrong while creating a Move activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @doc """
  Create an actor locally by its URL (AP ID)
  """
  @spec make_actor_from_url(String.t(), boolean()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_url(url, preload \\ false) do
    case fetch_and_prepare_actor_from_url(url) do
      {:ok, data} ->
        Actors.upsert_actor(data, preload)

      # Request returned 410
      {:error, :actor_deleted} ->
        Logger.info("Actor was deleted")
        {:error, :actor_deleted}

      e ->
        Logger.warn("Failed to make actor from url")
        {:error, e}
    end
  end

  @doc """
  Find an actor in our local database or call WebFinger to find what's its AP ID is and then fetch it
  """
  @spec find_or_make_actor_from_nickname(String.t(), atom() | nil) :: tuple()
  def find_or_make_actor_from_nickname(nickname, type \\ nil) do
    case Actors.get_actor_by_name(nickname, type) do
      %Actor{} = actor ->
        {:ok, actor}

      nil ->
        make_actor_from_nickname(nickname)
    end
  end

  @spec find_or_make_person_from_nickname(String.t()) :: tuple()
  def find_or_make_person_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Person)

  @spec find_or_make_group_from_nickname(String.t()) :: tuple()
  def find_or_make_group_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Group)

  @doc """
  Create an actor inside our database from username, using WebFinger to find out its AP ID and then fetch it
  """
  @spec make_actor_from_nickname(String.t()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_nickname(nickname) do
    case WebFinger.finger(nickname) do
      {:ok, %{"url" => url}} when not is_nil(url) ->
        make_actor_from_url(url)

      _e ->
        {:error, "No ActivityPub URL found in WebFinger"}
    end
  end

  @spec is_create_activity?(Activity.t()) :: boolean
  defp is_create_activity?(%Activity{data: %{"type" => "Create"}}), do: true
  defp is_create_activity?(_), do: false

  @spec is_announce_activity?(Activity.t()) :: boolean
  defp is_announce_activity?(%Activity{data: %{"type" => "Announce"}}), do: true
  defp is_announce_activity?(_), do: false

  @doc """
  Publish an activity to all appropriated audiences inboxes
  """
  # credo:disable-for-lines:47
  @spec publish(Actor.t(), Activity.t()) :: :ok
  def publish(actor, activity) do
    Logger.debug("Publishing an activity")
    Logger.debug(inspect(activity))

    public = Visibility.is_public?(activity)
    Logger.debug("is public ? #{public}")

    if public && is_create_activity?(activity) && Config.get([:instance, :allow_relay]) do
      Logger.info(fn -> "Relaying #{activity.data["id"]} out" end)

      Relay.publish(activity)
    end

    followers =
      if actor.followers_url in activity.recipients do
        Actors.list_external_followers_for_actor(actor)
      else
        []
      end

    # If we want to send to all members of the group, because this server is the one the group is on
    members =
      if is_announce_activity?(activity) and actor.type == :Group and
           actor.members_url in activity.recipients and is_nil(actor.domain) do
        Actors.list_external_members_for_group(actor)
      else
        []
      end

    remote_inboxes =
      (remote_actors(activity) ++ followers ++ members)
      |> Enum.map(fn follower -> follower.shared_inbox_url || follower.inbox_url end)
      |> Enum.uniq()

    {:ok, data} = Transmogrifier.prepare_outgoing(activity.data)
    json = Jason.encode!(data)
    Logger.debug(fn -> "Remote inboxes are : #{inspect(remote_inboxes)}" end)

    Enum.each(remote_inboxes, fn inbox ->
      Federator.enqueue(:publish_single_ap, %{
        inbox: inbox,
        json: json,
        actor: actor,
        id: activity.data["id"]
      })
    end)
  end

  @doc """
  Publish an activity to a specific inbox
  """
  def publish_one(%{inbox: inbox, json: json, actor: actor, id: id}) do
    Logger.info("Federating #{id} to #{inbox}")
    %URI{host: host, path: path} = URI.parse(inbox)

    digest = Signature.build_digest(json)
    date = Signature.generate_date_header()

    # request_target = Signature.generate_request_target("POST", path)

    signature =
      Signature.sign(actor, %{
        "(request-target)": "post #{path}",
        host: host,
        "content-length": byte_size(json),
        digest: digest,
        date: date
      })

    HTTPoison.post(
      inbox,
      json,
      [
        {"Content-Type", "application/activity+json"},
        {"signature", signature},
        {"digest", digest},
        {"date", date}
      ],
      hackney: [pool: :default]
    )
  end

  # Fetching a remote actor's information through its AP ID
  @spec fetch_and_prepare_actor_from_url(String.t()) :: {:ok, struct()} | {:error, atom()} | any()
  defp fetch_and_prepare_actor_from_url(url) do
    Logger.debug("Fetching and preparing actor from url")
    Logger.debug(inspect(url))

    res =
      with %HTTPoison.Response{status_code: 200, body: body} <-
             HTTPoison.get!(url, [Accept: "application/activity+json"],
               follow_redirect: true,
               ssl: [{:versions, [:"tlsv1.2"]}]
             ),
           :ok <- Logger.debug("response okay, now decoding json"),
           {:ok, data} <- Jason.decode(body) do
        Logger.debug("Got activity+json response at actor's endpoint, now converting data")
        {:ok, Converter.Actor.as_to_model_data(data)}
      else
        # Actor is gone, probably deleted
        {:ok, %HTTPoison.Response{status_code: 410}} ->
          Logger.info("Response HTTP 410")
          {:error, :actor_deleted}

        e ->
          Logger.warn("Could not decode actor at fetch #{url}, #{inspect(e)}")
          {:error, e}
      end

    res
  end

  @doc """
  Return all public activities (events & comments) for an actor
  """
  @spec fetch_public_activities_for_actor(Actor.t(), integer(), integer()) :: map()
  def fetch_public_activities_for_actor(%Actor{} = actor, page \\ 1, limit \\ 10) do
    {:ok, events, total_events} = Events.list_public_events_for_actor(actor, page, limit)

    {:ok, comments, total_comments} =
      Conversations.list_public_comments_for_actor(actor, page, limit)

    event_activities = Enum.map(events, &event_to_activity/1)
    comment_activities = Enum.map(comments, &comment_to_activity/1)
    activities = event_activities ++ comment_activities

    %{elements: activities, total: total_events + total_comments}
  end

  # Create an activity from an event
  @spec event_to_activity(%Event{}, boolean()) :: Activity.t()
  defp event_to_activity(%Event{} = event, local \\ true) do
    %Activity{
      recipients: ["https://www.w3.org/ns/activitystreams#Public"],
      actor: event.organizer_actor.url,
      data: Converter.Event.model_to_as(event),
      local: local
    }
  end

  # Create an activity from a comment
  @spec comment_to_activity(%Comment{}, boolean()) :: Activity.t()
  defp comment_to_activity(%Comment{} = comment, local \\ true) do
    %Activity{
      recipients: ["https://www.w3.org/ns/activitystreams#Public"],
      actor: comment.actor.url,
      data: Converter.Comment.model_to_as(comment),
      local: local
    }
  end

  # Get recipients for an activity or object
  @spec get_recipients(map()) :: list()
  defp get_recipients(data) do
    Map.get(data, "to", []) ++ Map.get(data, "cc", [])
  end

  @spec create_event(map(), map()) :: {:ok, map()}
  defp create_event(args, additional) do
    with args <- prepare_args_for_event(args),
         {:ok, %Event{} = event} <- Events.create_event(args),
         event_as_data <- Convertible.model_to_as(event),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(event),
         create_data <-
           make_create_data(event_as_data, Map.merge(audience, additional)) do
      {:ok, event, create_data}
    end
  end

  @spec create_comment(map(), map()) :: {:ok, map()}
  defp create_comment(args, additional) do
    with args <- prepare_args_for_comment(args),
         {:ok, %Comment{} = comment} <- Conversations.create_comment(args),
         comment_as_data <- Convertible.model_to_as(comment),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(comment),
         create_data <-
           make_create_data(comment_as_data, Map.merge(audience, additional)) do
      {:ok, comment, create_data}
    end
  end

  @spec create_group(map(), map()) :: {:ok, map()}
  defp create_group(args, additional) do
    with args <- prepare_args_for_group(args),
         {:ok, %Actor{type: :Group} = group} <- Actors.create_group(args),
         group_as_data <- Convertible.model_to_as(group),
         audience <- %{"to" => ["https://www.w3.org/ns/activitystreams#Public"], "cc" => []},
         create_data <-
           make_create_data(group_as_data, Map.merge(audience, additional)) do
      {:ok, group, create_data}
    end
  end

  @spec create_todo_list(map(), map()) :: {:ok, map()}
  defp create_todo_list(args, additional) do
    with {:ok, %TodoList{actor_id: group_id} = todo_list} <- Todos.create_todo_list(args),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         todo_list_as_data <- Convertible.model_to_as(%{todo_list | actor: group}),
         audience <- %{"to" => [group.url], "cc" => []},
         create_data <-
           make_create_data(todo_list_as_data, Map.merge(audience, additional)) do
      {:ok, todo_list, create_data}
    end
  end

  @spec create_todo(map(), map()) :: {:ok, map()}
  defp create_todo(args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id, creator_id: creator_id} = todo} <-
           Todos.create_todo(args),
         %TodoList{actor_id: group_id} = todo_list <- Todos.get_todo_list(todo_list_id),
         %Actor{} = creator <- Actors.get_actor(creator_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         todo <- %{todo | todo_list: %{todo_list | actor: group}, creator: creator},
         todo_as_data <-
           Convertible.model_to_as(todo),
         audience <- %{"to" => [group.url], "cc" => []},
         create_data <-
           make_create_data(todo_as_data, Map.merge(audience, additional)) do
      {:ok, todo, create_data}
    end
  end

  defp create_resource(%{type: type} = args, additional) do
    args =
      case type do
        :folder ->
          args

        _ ->
          case Parser.parse(Map.get(args, :resource_url)) do
            {:ok, metadata} ->
              Map.put(args, :metadata, metadata)

            _ ->
              args
          end
      end

    with {:ok,
          %Resource{actor_id: group_id, creator_id: creator_id, parent_id: parent_id} = resource} <-
           Resources.create_resource(args),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} = creator <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group, creator: creator}),
         audience <- %{
           "to" => [group.url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         } do
      create_data =
        case parent_id do
          nil ->
            make_create_data(resource_as_data, Map.merge(audience, additional))

          parent_id ->
            # In case the resource has a parent we don't `Create` the resource but `Add` it to an existing resource
            parent = Resources.get_resource(parent_id)
            make_add_data(resource_as_data, parent, Map.merge(audience, additional))
        end

      {:ok, resource, create_data}
    else
      err ->
        Logger.error(inspect(err))
        err
    end
  end

  @spec check_for_tombstones(map()) :: Tombstone.t() | nil
  defp check_for_tombstones(%{url: url}), do: Tombstone.find_tombstone(url)
  defp check_for_tombstones(_), do: nil

  @spec update_event(Event.t(), map(), map()) :: {:ok, Event.t(), Activity.t()} | any()
  defp update_event(%Event{} = old_event, args, additional) do
    with args <- prepare_args_for_event(args),
         {:ok, %Event{} = new_event} <- Events.update_event(old_event, args),
         {:ok, true} <- Cachex.del(:activity_pub, "event_#{new_event.uuid}"),
         event_as_data <- Convertible.model_to_as(new_event),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_event),
         update_data <- make_update_data(event_as_data, Map.merge(audience, additional)) do
      {:ok, new_event, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec update_comment(Comment.t(), map(), map()) :: {:ok, Comment.t(), Activity.t()} | any()
  defp update_comment(%Comment{} = old_comment, args, additional) do
    with args <- prepare_args_for_comment(args),
         {:ok, %Comment{} = new_comment} <- Conversations.update_comment(old_comment, args),
         {:ok, true} <- Cachex.del(:activity_pub, "comment_#{new_comment.uuid}"),
         comment_as_data <- Convertible.model_to_as(new_comment),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_comment),
         update_data <- make_update_data(comment_as_data, Map.merge(audience, additional)) do
      {:ok, new_comment, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec update_actor(Actor.t(), map, map) :: {:ok, Actor.t(), Activity.t()} | any
  defp update_actor(%Actor{} = old_actor, args, additional) do
    with {:ok, %Actor{} = new_actor} <- Actors.update_actor(old_actor, args),
         actor_as_data <- Convertible.model_to_as(new_actor),
         {:ok, true} <- Cachex.del(:activity_pub, "actor_#{new_actor.preferred_username}"),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_actor),
         additional <- Map.merge(additional, %{"actor" => old_actor.url}),
         update_data <- make_update_data(actor_as_data, Map.merge(audience, additional)) do
      {:ok, new_actor, update_data}
    end
  end

  @spec update_actor(Todo.t(), map, map) :: {:ok, Todo.t(), Activity.t()} | any
  defp update_todo(%Todo{} = old_todo, args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id} = todo} <- Todos.update_todo(old_todo, args),
         %TodoList{actor_id: group_id} = todo_list <- Todos.get_todo_list(todo_list_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         todo_as_data <-
           Convertible.model_to_as(%{todo | todo_list: %{todo_list | actor: group}}),
         audience <- %{"to" => [group.url], "cc" => []},
         update_data <-
           make_update_data(todo_as_data, Map.merge(audience, additional)) do
      {:ok, todo, update_data}
    end
  end

  defp update_resource(%Resource{} = old_resource, %{parent_id: _parent_id} = args, additional) do
    move_resource(old_resource, args, additional)
  end

  # Simple rename
  defp update_resource(%Resource{} = old_resource, %{title: title} = _args, additional) do
    with {:ok, %Resource{actor_id: group_id, creator_id: creator_id} = resource} <-
           Resources.update_resource(old_resource, %{title: title}),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group}),
         audience <- %{
           "to" => [group.url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         },
         update_data <-
           make_update_data(resource_as_data, Map.merge(audience, additional)) do
      {:ok, resource, update_data}
    else
      err ->
        Logger.error(inspect(err))
        err
    end
  end

  defp move_resource(
         %Resource{parent_id: old_parent_id} = old_resource,
         %{parent_id: _new_parent_id} = args,
         additional
       ) do
    with {:ok,
          %Resource{actor_id: group_id, creator_id: creator_id, parent_id: new_parent_id} =
            resource} <-
           Resources.update_resource(old_resource, args),
         old_parent <- Resources.get_resource(old_parent_id),
         new_parent <- Resources.get_resource(new_parent_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         %Actor{url: creator_url} <- Actors.get_actor(creator_id),
         resource_as_data <-
           Convertible.model_to_as(%{resource | actor: group}),
         audience <- %{
           "to" => [group.url],
           "cc" => [],
           "actor" => creator_url,
           "attributedTo" => [creator_url]
         },
         move_data <-
           make_move_data(
             resource_as_data,
             old_parent,
             new_parent,
             Map.merge(audience, additional)
           ) do
      {:ok, resource, move_data}
    else
      err ->
        Logger.error(inspect(err))
        err
    end
  end

  @spec accept_follow(Follower.t(), map) :: {:ok, Follower.t(), Activity.t()} | any
  defp accept_follow(%Follower{} = follower, additional) do
    with {:ok, %Follower{} = follower} <- Actors.update_follower(follower, %{approved: true}),
         follower_as_data <- Convertible.model_to_as(follower),
         update_data <-
           make_accept_join_data(
             follower_as_data,
             Map.merge(additional, %{
               "id" => "#{Endpoint.url()}/accept/follow/#{follower.id}",
               "to" => [follower.actor.url],
               "cc" => [],
               "actor" => follower.target_actor.url
             })
           ) do
      {:ok, follower, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec accept_join(Participant.t(), map) :: {:ok, Participant.t(), Activity.t()} | any
  defp accept_join(%Participant{} = participant, additional) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participant, %{role: :participant}),
         Absinthe.Subscription.publish(Endpoint, participant.actor,
           event_person_participation_changed: participant.actor.id
         ),
         {:ok, _} <-
           Scheduler.before_event_notification(participant),
         participant_as_data <- Convertible.model_to_as(participant),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(participant),
         update_data <-
           make_accept_join_data(
             participant_as_data,
             Map.merge(Map.merge(audience, additional), %{
               "id" => "#{Endpoint.url()}/accept/join/#{participant.id}"
             })
           ) do
      {:ok, participant, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec accept_invite(Member.t(), map()) :: {:ok, Member.t(), Activity.t()} | any
  defp accept_invite(
         %Member{invited_by_id: invited_by_id, actor_id: actor_id} = member,
         _additional
       ) do
    with %Actor{} = inviter <- Actors.get_actor(invited_by_id),
         %Actor{url: actor_url} <- Actors.get_actor(actor_id),
         {:ok, %Member{url: member_url, id: member_id} = member} <-
           Actors.update_member(member, %{role: :member}),
         accept_data <- %{
           "type" => "Accept",
           "actor" => actor_url,
           "to" => [inviter.url],
           "cc" => [member.parent.url],
           "object" => member_url,
           "id" => "#{Endpoint.url()}/accept/invite/member/#{member_id}"
         } do
      {:ok, member, accept_data}
    end
  end

  @spec reject_join(Participant.t(), map()) :: {:ok, Participant.t(), Activity.t()} | any()
  defp reject_join(%Participant{} = participant, additional) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participant, %{role: :rejected}),
         Absinthe.Subscription.publish(Endpoint, participant.actor,
           event_person_participation_changed: participant.actor.id
         ),
         participant_as_data <- Convertible.model_to_as(participant),
         audience <-
           participant
           |> Audience.calculate_to_and_cc_from_mentions()
           |> Map.merge(additional),
         reject_data <- %{
           "type" => "Reject",
           "object" => participant_as_data
         },
         update_data <-
           reject_data
           |> Map.merge(audience)
           |> Map.merge(%{
             "id" => "#{Endpoint.url()}/reject/join/#{participant.id}"
           }) do
      {:ok, participant, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  @spec reject_follow(Follower.t(), map()) :: {:ok, Follower.t(), Activity.t()} | any()
  defp reject_follow(%Follower{} = follower, additional) do
    with {:ok, %Follower{} = follower} <- Actors.delete_follower(follower),
         follower_as_data <- Convertible.model_to_as(follower),
         audience <-
           follower.actor |> Audience.calculate_to_and_cc_from_mentions() |> Map.merge(additional),
         reject_data <- %{
           "to" => [follower.actor.url],
           "type" => "Reject",
           "actor" => follower.target_actor.url,
           "object" => follower_as_data
         },
         update_data <-
           audience
           |> Map.merge(reject_data)
           |> Map.merge(%{
             "id" => "#{Endpoint.url()}/reject/follow/#{follower.id}"
           }) do
      {:ok, follower, update_data}
    else
      err ->
        Logger.error("Something went wrong while creating an update activity")
        Logger.debug(inspect(err))
        err
    end
  end

  # Prepare and sanitize arguments for events
  defp prepare_args_for_event(args) do
    # If title is not set: we are not updating it
    args =
      if Map.has_key?(args, :title) && !is_nil(args.title),
        do: Map.update(args, :title, "", &String.trim(HtmlSanitizeEx.strip_tags(&1))),
        else: args

    # If we've been given a description (we might not get one if updating)
    # sanitize it, HTML it, and extract tags & mentions from it
    args =
      if Map.has_key?(args, :description) && !is_nil(args.description) do
        {description, mentions, tags} =
          APIUtils.make_content_html(
            String.trim(args.description),
            Map.get(args, :tags, []),
            "text/html"
          )

        mentions = ConverterUtils.fetch_mentions(Map.get(args, :mentions, []) ++ mentions)

        Map.merge(args, %{
          description: description,
          mentions: mentions,
          tags: tags
        })
      else
        args
      end

    # Check that we can only allow anonymous participation if our instance allows it
    {_, options} =
      Map.get_and_update(
        Map.get(args, :options, %{anonymous_participation: false}),
        :anonymous_participation,
        fn value ->
          {value, value && Mobilizon.Config.anonymous_participation?()}
        end
      )

    args = Map.put(args, :options, options)

    Map.update(args, :tags, [], &ConverterUtils.fetch_tags/1)
  end

  # Prepare and sanitize arguments for comments
  defp prepare_args_for_comment(args) do
    with in_reply_to_comment <-
           args |> Map.get(:in_reply_to_comment_id) |> Conversations.get_comment_with_preload(),
         event <- args |> Map.get(:event_id) |> handle_event_for_comment(),
         args <- Map.update(args, :visibility, :public, & &1),
         {text, mentions, tags} <-
           APIUtils.make_content_html(
             args |> Map.get(:text, "") |> String.trim(),
             # Can't put additional tags on a comment
             [],
             "text/html"
           ),
         tags <- ConverterUtils.fetch_tags(tags),
         mentions <- Map.get(args, :mentions, []) ++ ConverterUtils.fetch_mentions(mentions),
         args <-
           Map.merge(args, %{
             actor_id: Map.get(args, :actor_id),
             text: text,
             mentions: mentions,
             tags: tags,
             event: event,
             in_reply_to_comment: in_reply_to_comment,
             in_reply_to_comment_id:
               if(is_nil(in_reply_to_comment), do: nil, else: Map.get(in_reply_to_comment, :id)),
             origin_comment_id:
               if(is_nil(in_reply_to_comment),
                 do: nil,
                 else: Comment.get_thread_id(in_reply_to_comment)
               )
           }) do
      args
    end
  end

  @spec handle_event_for_comment(String.t() | integer() | nil) :: Event.t() | nil
  defp handle_event_for_comment(event_id) when not is_nil(event_id) do
    case Events.get_event_with_preload(event_id) do
      {:ok, %Event{} = event} -> event
      {:error, :event_not_found} -> nil
    end
  end

  defp handle_event_for_comment(nil), do: nil

  defp prepare_args_for_group(args) do
    with preferred_username <-
           args |> Map.get(:preferred_username) |> HtmlSanitizeEx.strip_tags() |> String.trim(),
         summary <- args |> Map.get(:summary, "") |> String.trim(),
         {summary, _mentions, _tags} <-
           summary |> String.trim() |> APIUtils.make_content_html([], "text/html") do
      %{args | preferred_username: preferred_username, summary: summary}
    end
  end

  defp prepare_args_for_report(args) do
    with {:reporter, %Actor{} = reporter_actor} <-
           {:reporter, Actors.get_actor!(args.reporter_id)},
         {:reported, %Actor{} = reported_actor} <-
           {:reported, Actors.get_actor!(args.reported_id)},
         content <- HtmlSanitizeEx.strip_tags(args.content),
         event <- Conversations.get_comment(Map.get(args, :event_id)),
         {:get_report_comments, comments} <-
           {:get_report_comments,
            Conversations.list_comments_by_actor_and_ids(
              reported_actor.id,
              Map.get(args, :comments_ids, [])
            )} do
      Map.merge(args, %{
        reporter: reporter_actor,
        reported: reported_actor,
        content: content,
        event: event,
        comments: comments
      })
    end
  end

  defp check_for_actor_key_rotation(%Actor{} = actor) do
    if Actors.should_rotate_actor_key(actor) do
      Actors.schedule_key_rotation(
        actor,
        Application.get_env(:mobilizon, :activitypub)[:actor_key_rotation_delay]
      )
    end

    :ok
  end
end
