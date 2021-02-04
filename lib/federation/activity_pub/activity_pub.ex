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
    Discussions,
    Events,
    Posts,
    Resources,
    Share,
    Users
  }

  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Tombstone

  alias Mobilizon.Federation.ActivityPub.{
    Activity,
    Audience,
    Federator,
    Fetcher,
    Preloader,
    Refresher,
    Relay,
    Transmogrifier,
    Types,
    Visibility
  }

  alias Mobilizon.Federation.ActivityPub.Types.{Managable, Ownable}

  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Federation.WebFinger

  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Storage.Page

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Email.{Admin, Group, Mailer}

  require Logger

  @public_ap_adress "https://www.w3.org/ns/activitystreams#Public"

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
  @spec fetch_object_from_url(String.t(), Keyword.t()) ::
          {:ok, struct()} | {:error, any()}
  def fetch_object_from_url(url, options \\ []) do
    Logger.info("Fetching object from url #{url}")
    force_fetch = Keyword.get(options, :force, false)

    with {:not_http, true} <- {:not_http, String.starts_with?(url, "http")},
         {:existing, nil} <-
           {:existing, Tombstone.find_tombstone(url)},
         {:existing, nil} <- {:existing, Events.get_event_by_url(url)},
         {:existing, nil} <-
           {:existing, Discussions.get_discussion_by_url(url)},
         {:existing, nil} <- {:existing, Discussions.get_comment_from_url(url)},
         {:existing, nil} <- {:existing, Resources.get_resource_by_url(url)},
         {:existing, nil} <- {:existing, Posts.get_post_by_url(url)},
         {:existing, nil} <-
           {:existing, Actors.get_actor_by_url_2(url)},
         {:existing, nil} <- {:existing, Actors.get_member_by_url(url)},
         :ok <- Logger.info("Data for URL not found anywhere, going to fetch it"),
         {:ok, _activity, entity} <- Fetcher.fetch_and_create(url, options) do
      Logger.debug("Going to preload the new entity")
      Preloader.maybe_preload(entity)
    else
      {:existing, entity} ->
        Logger.debug("Entity is already existing")

        res =
          if force_fetch and not are_same_origin?(url, Endpoint.url()) do
            Logger.debug("Entity is external and we want a force fetch")

            case Fetcher.fetch_and_update(url, options) do
              {:ok, _activity, entity} ->
                {:ok, entity}

              {:error, "Gone"} ->
                {:error, "Gone", entity}

              {:error, "Not found"} ->
                {:error, "Not found", entity}
            end
          else
            {:ok, entity}
          end

        Logger.debug("Going to preload an existing entity")

        case res do
          {:ok, entity} ->
            Preloader.maybe_preload(entity)

          {:error, status, entity} ->
            {:ok, entity} = Preloader.maybe_preload(entity)
            {:error, status, entity}

          err ->
            err
        end

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

  @spec get_or_fetch_actor_by_url(String.t(), boolean()) :: {:ok, Actor.t()} | {:error, any()}
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
              :event -> Types.Events.create(args, additional)
              :comment -> Types.Comments.create(args, additional)
              :discussion -> Types.Discussions.create(args, additional)
              :actor -> Types.Actors.create(args, additional)
              :todo_list -> Types.TodoLists.create(args, additional)
              :todo -> Types.Todos.create(args, additional)
              :resource -> Types.Resources.create(args, additional)
              :post -> Types.Posts.create(args, additional)
            end),
         {:ok, activity} <- create_activity(create_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
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
  @spec update(struct(), map(), boolean, map()) :: {:ok, Activity.t(), struct()} | any()
  def update(old_entity, args, local \\ false, additional \\ %{}) do
    Logger.debug("updating an activity")
    Logger.debug(inspect(args))

    with {:ok, entity, update_data} <- Managable.update(old_entity, args, additional),
         {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
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
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
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
        :invite -> reject_invite(entity, additional)
      end

    with {:ok, activity} <- create_activity(update_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
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
    with {:ok, %Actor{id: object_owner_actor_id}} <- get_or_fetch_actor_by_url(object["actor"]),
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
  def follow(
        %Actor{} = follower,
        %Actor{} = followed,
        activity_id \\ nil,
        local \\ true,
        additional \\ %{}
      ) do
    with {:different_actors, true} <- {:different_actors, followed.id != follower.id},
         {:ok, activity_data, %Follower{} = follower} <-
           Types.Actors.follow(
             follower,
             followed,
             local,
             Map.merge(additional, %{"activity_id" => activity_id})
           ),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, follower}
    else
      {:error, err, msg} when err in [:already_following, :suspended, :no_person] ->
        {:error, msg}

      {:different_actors, _} ->
        {:error, "Can't follow yourself"}
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

  def delete(object, actor, local \\ true, additional \\ %{}) do
    with {:ok, activity_data, actor, object} <-
           Managable.delete(object, actor, local, additional),
         group <- Ownable.group_actor(object),
         :ok <- check_for_actor_key_rotation(actor),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity, group) do
      {:ok, activity, object}
    end
  end

  def join(entity_to_join, actor_joining, local \\ true, additional \\ %{})

  def join(%Event{} = event, %Actor{} = actor, local, additional) do
    with {:ok, activity_data, participant} <- Types.Events.join(event, actor, local, additional),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, participant}
    else
      {:maximum_attendee_capacity, err} ->
        {:maximum_attendee_capacity, err}

      {:accept, accept} ->
        accept
    end
  end

  def join(%Actor{type: :Group} = group, %Actor{} = actor, local, additional) do
    with {:ok, activity_data, %Member{} = member} <-
           Types.Actors.join(group, actor, local, additional),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, member}
    else
      {:accept, accept} ->
        accept
    end
  end

  def leave(object, actor, local \\ true, additional \\ %{})

  @doc """
  Leave an event or a group
  """
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

  def leave(
        %Actor{type: :Group, id: group_id, url: group_url, members_url: group_members_url},
        %Actor{id: actor_id, url: actor_url},
        local,
        additional
      ) do
    with {:member, {:ok, %Member{id: member_id} = member}} <-
           {:member, Actors.get_member(actor_id, group_id)},
         {:is_not_only_admin, true} <-
           {:is_not_only_admin,
            Map.get(additional, :force_member_removal, false) ||
              !Actors.is_only_administrator?(member_id, group_id)},
         {:delete, {:ok, %Member{} = member}} <- {:delete, Actors.delete_member(member)},
         leave_data <- %{
           "to" => [group_members_url],
           "cc" => [group_url],
           "attributedTo" => group_url,
           "type" => "Leave",
           "actor" => actor_url,
           "object" => group_url
         },
         {:ok, activity} <- create_activity(leave_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
      {:ok, activity, member}
    end
  end

  def remove(
        %Member{} = member,
        %Actor{type: :Group, url: group_url, members_url: group_members_url},
        %Actor{url: moderator_url},
        local,
        _additional \\ %{}
      ) do
    with {:ok, %Member{id: member_id}} <- Actors.update_member(member, %{role: :rejected}),
         %Member{} = member <- Actors.get_member(member_id),
         :ok <- Group.send_notification_to_removed_member(member),
         remove_data <- %{
           "to" => [group_members_url],
           "type" => "Remove",
           "actor" => moderator_url,
           "object" => member.url,
           "origin" => group_url
         },
         {:ok, activity} <- create_activity(remove_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity) do
      {:ok, activity, member}
    end
  end

  @spec invite(Actor.t(), Actor.t(), Actor.t(), boolean, map()) ::
          {:ok, map(), Member.t()} | {:error, :member_not_found}
  def invite(
        %Actor{url: group_url, id: group_id, members_url: members_url} = group,
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
           "attributedTo" => group_url,
           "actor" => actor_url,
           "object" => group_url,
           "target" => target_actor_url,
           "id" => member_url
         },
         {:ok, activity} <-
           create_activity(
             invite_data
             |> Map.merge(%{"to" => [target_actor_url, members_url], "cc" => [group_url]})
             |> Map.merge(additional),
             local
           ),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity),
         :ok <- Group.send_invite_to_user(member) do
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
              :resource -> Types.Resources.move(old_entity, args, additional)
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

  def flag(args, local \\ false, additional \\ %{}) do
    with {report, report_as_data} <- Types.Reports.flag(args, local, additional),
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

  @doc """
  Create an actor locally by its URL (AP ID)
  """
  @spec make_actor_from_url(String.t(), boolean()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_url(url, preload \\ false) do
    if are_same_origin?(url, Endpoint.url()) do
      {:error, "Can't make a local actor from URL"}
    else
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

  @spec convert_members_in_recipients(list(String.t())) :: {list(String.t()), list(Actor.t())}
  defp convert_members_in_recipients(recipients) do
    Enum.reduce(recipients, {recipients, []}, fn recipient, {recipients, member_actors} = acc ->
      case Actors.get_group_by_members_url(recipient) do
        # If the group is local just add external members
        %Actor{domain: domain} = group when is_nil(domain) ->
          {Enum.filter(recipients, fn recipient -> recipient != group.members_url end),
           member_actors ++ Actors.list_external_actors_members_for_group(group)}

        # If it's remote add the remote group actor as well
        %Actor{} = group ->
          {Enum.filter(recipients, fn recipient -> recipient != group.members_url end),
           member_actors ++ Actors.list_external_actors_members_for_group(group) ++ [group]}

        _ ->
          acc
      end
    end)
  end

  defp convert_followers_in_recipients(recipients) do
    Enum.reduce(recipients, {recipients, []}, fn recipient, {recipients, follower_actors} = acc ->
      case Actors.get_actor_by_followers_url(recipient) do
        %Actor{} = group ->
          {Enum.filter(recipients, fn recipient -> recipient != group.followers_url end),
           follower_actors ++ Actors.list_external_followers_for_actor(group)}

        _ ->
          acc
      end
    end)
  end

  # @spec is_announce_activity?(Activity.t()) :: boolean
  # defp is_announce_activity?(%Activity{data: %{"type" => "Announce"}}), do: true
  # defp is_announce_activity?(_), do: false

  @doc """
  Publish an activity to all appropriated audiences inboxes
  """
  # credo:disable-for-lines:47
  @spec publish(Actor.t(), Activity.t()) :: :ok
  def publish(actor, %Activity{recipients: recipients} = activity) do
    Logger.debug("Publishing an activity")
    Logger.debug(inspect(activity))

    public = Visibility.is_public?(activity)
    Logger.debug("is public ? #{public}")

    if public && is_create_activity?(activity) && Config.get([:instance, :allow_relay]) do
      Logger.info(fn -> "Relaying #{activity.data["id"]} out" end)

      Relay.publish(activity)
    end

    recipients = Enum.uniq(recipients)

    {recipients, followers} = convert_followers_in_recipients(recipients)

    {recipients, members} = convert_members_in_recipients(recipients)

    remote_inboxes =
      (remote_actors(recipients) ++ followers ++ members)
      |> Enum.map(fn actor -> actor.shared_inbox_url || actor.inbox_url end)
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

    Tesla.post(
      inbox,
      json,
      headers: [
        {"Content-Type", "application/activity+json"},
        {"signature", signature},
        {"digest", digest},
        {"date", date}
      ]
    )
  end

  # Fetching a remote actor's information through its AP ID
  @spec fetch_and_prepare_actor_from_url(String.t()) :: {:ok, struct()} | {:error, atom()} | any()
  defp fetch_and_prepare_actor_from_url(url) do
    Logger.debug("Fetching and preparing actor from url")
    Logger.debug(inspect(url))

    res =
      with {:ok, %{status: 200, body: body}} <-
             Tesla.get(url,
               headers: [{"Accept", "application/activity+json"}],
               follow_redirect: true
             ),
           :ok <- Logger.debug("response okay, now decoding json"),
           {:ok, data} <- Jason.decode(body) do
        Logger.debug("Got activity+json response at actor's endpoint, now converting data")
        {:ok, Converter.Actor.as_to_model_data(data)}
      else
        # Actor is gone, probably deleted
        {:ok, %{status: 410}} ->
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
  def fetch_public_activities_for_actor(%Actor{id: actor_id} = actor, page \\ 1, limit \\ 10) do
    %Actor{id: relay_actor_id} = Relay.get_actor()

    %Page{total: total_events, elements: events} =
      if actor_id == relay_actor_id do
        Events.list_public_local_events(page, limit)
      else
        Events.list_public_events_for_actor(actor, page, limit)
      end

    %Page{total: total_comments, elements: comments} =
      if actor_id == relay_actor_id do
        Discussions.list_local_comments(page, limit)
      else
        Discussions.list_public_comments_for_actor(actor, page, limit)
      end

    event_activities = Enum.map(events, &event_to_activity/1)
    comment_activities = Enum.map(comments, &comment_to_activity/1)
    activities = event_activities ++ comment_activities

    %{elements: activities, total: total_events + total_comments}
  end

  # Create an activity from an event
  @spec event_to_activity(%Event{}, boolean()) :: Activity.t()
  defp event_to_activity(%Event{} = event, local \\ true) do
    %Activity{
      recipients: [@public_ap_adress],
      actor: event.organizer_actor.url,
      data: event |> Convertible.model_to_as() |> make_create_data(%{"to" => @public_ap_adress}),
      local: local
    }
  end

  # Create an activity from a comment
  @spec comment_to_activity(%Comment{}, boolean()) :: Activity.t()
  defp comment_to_activity(%Comment{} = comment, local \\ true) do
    %Activity{
      recipients: [@public_ap_adress],
      actor: comment.actor.url,
      data:
        comment |> Convertible.model_to_as() |> make_create_data(%{"to" => @public_ap_adress}),
      local: local
    }
  end

  # Get recipients for an activity or object
  @spec get_recipients(map()) :: list()
  defp get_recipients(data) do
    Map.get(data, "to", []) ++ Map.get(data, "cc", [])
  end

  @spec check_for_tombstones(map()) :: Tombstone.t() | nil
  defp check_for_tombstones(%{url: url}), do: Tombstone.find_tombstone(url)
  defp check_for_tombstones(_), do: nil

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
           Scheduler.trigger_notifications_for_participant(participant),
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

  @spec accept_join(Member.t(), map) :: {:ok, Member.t(), Activity.t()} | any
  defp accept_join(%Member{} = member, additional) do
    with {:ok, %Member{} = member} <-
           Actors.update_member(member, %{role: :member}),
         _ <-
           unless(is_nil(member.parent.domain),
             do: Refresher.fetch_group(member.parent.url, member.actor)
           ),
         Absinthe.Subscription.publish(Endpoint, member.actor,
           group_membership_changed: member.actor.id
         ),
         member_as_data <- Convertible.model_to_as(member),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(member),
         update_data <-
           make_accept_join_data(
             member_as_data,
             Map.merge(Map.merge(audience, additional), %{
               "id" => "#{Endpoint.url()}/accept/join/#{member.id}"
             })
           ) do
      {:ok, member, update_data}
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
         {:ok, %Member{id: member_id} = member} <-
           Actors.update_member(member, %{role: :member}),
         accept_data <- %{
           "type" => "Accept",
           "attributedTo" => member.parent.url,
           "to" => [inviter.url, member.parent.members_url],
           "cc" => [member.parent.url],
           "actor" => actor_url,
           "object" => Convertible.model_to_as(member),
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

  @spec reject_invite(Member.t(), map()) :: {:ok, Member.t(), Activity.t()} | any
  defp reject_invite(
         %Member{invited_by_id: invited_by_id, actor_id: actor_id} = member,
         _additional
       ) do
    with %Actor{} = inviter <- Actors.get_actor(invited_by_id),
         %Actor{url: actor_url} <- Actors.get_actor(actor_id),
         {:ok, %Member{url: member_url, id: member_id} = member} <-
           Actors.delete_member(member),
         accept_data <- %{
           "type" => "Reject",
           "actor" => actor_url,
           "attributedTo" => member.parent.url,
           "to" => [inviter.url, member.parent.members_url],
           "cc" => [member.parent.url],
           "object" => member_url,
           "id" => "#{Endpoint.url()}/reject/invite/member/#{member_id}"
         } do
      {:ok, member, accept_data}
    end
  end
end
