# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub.ex

defmodule Mobilizon.Service.ActivityPub do
  @moduledoc """
  # ActivityPub

  Every ActivityPub method
  """

  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Comment}
  alias Mobilizon.Service.ActivityPub.Transmogrifier
  alias Mobilizon.Service.WebFinger
  alias Mobilizon.Activity

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors.Follower

  alias Mobilizon.Service.Federator
  alias Mobilizon.Service.HTTPSignatures

  require Logger
  import Mobilizon.Service.ActivityPub.Utils

  @doc """
  Get recipients for an activity or object
  """
  @spec get_recipients(map()) :: list()
  def get_recipients(data) do
    (data["to"] || []) ++ (data["cc"] || [])
  end

  @doc """
  Wraps an object into an activity
  """
  # TODO: Rename me
  @spec insert(map(), boolean()) :: {:ok, %Activity{}} | {:error, any()}
  def insert(map, local \\ true) when is_map(map) do
    with map <- lazy_put_activity_defaults(map),
         {:ok, object} <- insert_full_object(map) do
      object_id = if is_map(map["object"]), do: map["object"]["id"], else: map["id"]

      map = if local, do: Map.put(map, "id", "#{object_id}/activity"), else: map

      activity = %Activity{
        data: map,
        local: local,
        actor: map["actor"],
        recipients: get_recipients(map)
      }

      # Notification.create_notifications(activity)
      # stream_out(activity)
      {:ok, activity, object}
    else
      %Activity{} = activity -> {:ok, activity}
      error -> {:error, error}
    end
  end

  @doc """
  Fetch an object from an URL, from our local database of events and comments, then eventually remote
  """
  # TODO: Make database calls parallel
  @spec fetch_object_from_url(String.t()) :: {:ok, %Event{}} | {:ok, %Comment{}} | {:error, any()}
  def fetch_object_from_url(url) do
    Logger.info("Fetching object from url #{url}")

    with true <- String.starts_with?(url, "http"),
         nil <- Events.get_event_by_url(url),
         nil <- Events.get_comment_from_url(url),
         {:error, :actor_not_found} <- Actors.get_actor_by_url(url),
         {:ok, %{body: body, status_code: code}} when code in 200..299 <-
           HTTPoison.get(
             url,
             [Accept: "application/activity+json"],
             follow_redirect: true,
             timeout: 10_000,
             recv_timeout: 20_000
           ),
         {:ok, data} <- Jason.decode(body),
         params <- %{
           "type" => "Create",
           "to" => data["to"],
           "cc" => data["cc"],
           "actor" => data["attributedTo"],
           "object" => data
         },
         {:ok, activity} <- Transmogrifier.handle_incoming(params) do
      case data["type"] do
        "Event" ->
          {:ok, Events.get_event_by_url!(activity.data["object"]["id"])}

        "Note" ->
          {:ok, Events.get_comment_full_from_url!(activity.data["object"]["id"])}

        "Actor" ->
          {:ok, Actors.get_actor_by_url!(activity.data["object"]["id"], true)}

        other ->
          {:error, other}
      end
    else
      %Event{url: event_url} -> {:ok, Events.get_event_by_url!(event_url)}
      %Comment{url: comment_url} -> {:ok, Events.get_comment_full_from_url!(comment_url)}
      %Actor{url: actor_url} -> {:ok, Actors.get_actor_by_url!(actor_url, true)}
      e -> {:error, e}
    end
  end

  @doc """
  Create an activity of type "Create"
  """
  def create(%{to: to, actor: actor, object: object} = params) do
    Logger.debug("creating an activity")
    Logger.debug(inspect(params))
    Logger.debug(inspect(object))
    additional = params[:additional] || %{}
    # only accept false as false value
    local = !(params[:local] == false)
    published = params[:published]

    with create_data <-
           make_create_data(
             %{to: to, actor: actor, published: published, object: object},
             additional
           ),
         :ok <- Logger.debug(inspect(create_data)),
         {:ok, activity, _object} <- insert(create_data, local),
         :ok <- maybe_federate(activity) do
      # {:ok, actor} <- Actors.increase_event_count(actor) do
      {:ok, activity}
    else
      err ->
        Logger.error("Something went wrong")
        Logger.error(inspect(err))
        err
    end
  end

  def accept(%{to: to, actor: actor, object: object} = params) do
    # only accept false as false value
    local = !(params[:local] == false)

    with data <- %{"to" => to, "type" => "Accept", "actor" => actor, "object" => object},
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  def update(%{to: to, cc: cc, actor: actor, object: object} = params) do
    # only accept false as false value
    local = !(params[:local] == false)

    with data <- %{
           "to" => to,
           "cc" => cc,
           "type" => "Update",
           "actor" => actor,
           "object" => object
         },
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  # TODO: This is weird, maybe we shouldn't check here if we can make the activity.
  # def like(
  #       %Actor{url: url} = actor,
  #       object,
  #       activity_id \\ nil,
  #       local \\ true
  #     ) do
  #   with nil <- get_existing_like(url, object),
  #        like_data <- make_like_data(user, object, activity_id),
  #        {:ok, activity, _object} <- insert(like_data, local),
  #        {:ok, object} <- add_like_to_object(activity, object),
  #        :ok <- maybe_federate(activity) do
  #     {:ok, activity, object}
  #   else
  #     %Activity{} = activity -> {:ok, activity, object}
  #     error -> {:error, error}
  #   end
  # end

  # def unlike(
  #       %User{} = actor,
  #       %Object{} = object,
  #       activity_id \\ nil,
  #       local \\ true
  #     ) do
  #   with %Activity{} = like_activity <- get_existing_like(actor.ap_id, object),
  #        unlike_data <- make_unlike_data(actor, like_activity, activity_id),
  #        {:ok, unlike_activity, _object} <- insert(unlike_data, local),
  #        {:ok, _activity} <- Repo.delete(like_activity),
  #        {:ok, object} <- remove_like_from_object(like_activity, object),
  #        :ok <- maybe_federate(unlike_activity) do
  #     {:ok, unlike_activity, like_activity, object}
  #   else
  #     _e -> {:ok, object}
  #   end
  # end

  # def announce(
  #       %Actor{} = actor,
  #       object,
  #       activity_id \\ nil,
  #       local \\ true
  #     ) do
  #   #with true <- is_public?(object),
  #        with announce_data <- make_announce_data(actor, object, activity_id),
  #        {:ok, activity, _object} <- insert(announce_data, local),
  #       #  {:ok, object} <- add_announce_to_object(activity, object),
  #        :ok <- maybe_federate(activity) do
  #     {:ok, activity, object}
  #   else
  #     error -> {:error, error}
  #   end
  # end

  # def unannounce(
  #       %Actor{} = actor,
  #       object,
  #       activity_id \\ nil,
  #       local \\ true
  #     ) do
  #   with %Activity{} = announce_activity <- get_existing_announce(actor.ap_id, object),
  #        unannounce_data <- make_unannounce_data(actor, announce_activity, activity_id),
  #        {:ok, unannounce_activity, _object} <- insert(unannounce_data, local),
  #        :ok <- maybe_federate(unannounce_activity),
  #        {:ok, _activity} <- Repo.delete(announce_activity),
  #        {:ok, object} <- remove_announce_from_object(announce_activity, object) do
  #     {:ok, unannounce_activity, object}
  #   else
  #     _e -> {:ok, object}
  #   end
  # end

  @doc """
  Make an actor follow another
  """
  def follow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{id: follow_id}} <- Actor.follow(followed, follower, true),
         activity_follow_id <-
           activity_id || "#{MobilizonWeb.Endpoint.url()}/follow/#{follow_id}/activity",
         data <- make_follow_data(followed, follower, activity_follow_id),
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    else
      {err, _} when err in [:already_following, :suspended] ->
        {:error, err}
    end
  end

  @doc """
  Make an actor unfollow another
  """
  @spec unfollow(Actor.t(), Actor.t(), String.t(), boolean()) :: {:ok, map()} | any()
  def unfollow(%Actor{} = followed, %Actor{} = follower, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{id: follow_id}} <- Actor.unfollow(followed, follower),
         # We recreate the follow activity
         data <- make_follow_data(followed, follower, follow_id),
         {:ok, follow_activity, _object} <- insert(data, local),
         unfollow_data <- make_unfollow_data(follower, followed, follow_activity, activity_id),
         {:ok, activity, _object} <- insert(unfollow_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    else
      err ->
        Logger.error(inspect(err))
        err
    end
  end

  def delete(object, local \\ true)

  def delete(%Event{url: url, organizer_actor: actor} = event, local) do
    data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => url,
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with {:ok, _} <- Events.delete_event(event),
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  def delete(%Comment{url: url, actor: actor} = comment, local) do
    data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => url,
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with {:ok, _} <- Events.delete_comment(comment),
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  def delete(%Actor{url: url} = actor, local) do
    data = %{
      "type" => "Delete",
      "actor" => url,
      "object" => url,
      "to" => [url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with {:ok, _} <- Actors.delete_actor(actor),
         {:ok, activity, _object} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  def flag(params) do
    # only accept false as false value
    local = !(params[:local] == false)
    forward = !(params[:forward] == false)

    additional = params[:additional] || %{}

    additional =
      if forward do
        Map.merge(additional, %{"to" => [], "cc" => [params.reported_actor_url]})
      else
        Map.merge(additional, %{"to" => [], "cc" => []})
      end

    with flag_data <- make_flag_data(params, additional),
         {:ok, activity, report} <- insert(flag_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, report}
    end
  end

  @doc """
  Create an actor locally by it's URL (AP ID)
  """
  @spec make_actor_from_url(String.t(), boolean()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_url(url, preload \\ false) do
    case fetch_and_prepare_actor_from_url(url) do
      {:ok, data} ->
        Actors.insert_or_update_actor(data, preload)

      # Request returned 410
      {:error, :actor_deleted} ->
        {:error, :actor_deleted}

      e ->
        Logger.error("Failed to make actor from url")
        Logger.error(inspect(e))
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
  Create an actor inside our database from username, using WebFinger to find out it's AP ID and then fetch it
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

  @doc """
  Publish an activity to all appropriated audiences inboxes
  """
  def publish(actor, activity) do
    Logger.debug("Publishing an activity")

    followers =
      if actor.followers_url in activity.recipients do
        Actor.get_full_followers(actor) |> Enum.filter(fn follower -> is_nil(follower.domain) end)
      else
        []
      end

    remote_inboxes =
      (remote_actors(activity) ++ followers)
      |> Enum.map(fn follower -> follower.shared_inbox_url end)
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

    digest = HTTPSignatures.build_digest(json)
    date = HTTPSignatures.generate_date_header()
    request_target = HTTPSignatures.generate_request_target("POST", path)

    signature =
      HTTPSignatures.sign(actor, %{
        host: host,
        "content-length": byte_size(json),
        "(request-target)": request_target,
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

  # Fetching a remote actor's information through it's AP ID
  @spec fetch_and_prepare_actor_from_url(String.t()) :: {:ok, struct()} | {:error, atom()} | any()
  defp fetch_and_prepare_actor_from_url(url) do
    Logger.debug("Fetching and preparing actor from url")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, [Accept: "application/activity+json"], follow_redirect: true),
         {:ok, data} <- Jason.decode(body) do
      actor_data_from_actor_object(data)
    else
      # Actor is gone, probably deleted
      {:ok, %HTTPoison.Response{status_code: 410}} ->
        {:error, :actor_deleted}

      e ->
        Logger.error("Could not decode actor at fetch #{url}, #{inspect(e)}")
        e
    end
  end

  @doc """
  Creating proper actor data struct from AP data


  Convert ActivityPub data to our internal format
  """
  @spec actor_data_from_actor_object(map()) :: {:ok, map()}
  def actor_data_from_actor_object(data) when is_map(data) do
    avatar =
      data["icon"]["url"] &&
        %{
          "name" => data["icon"]["name"] || "avatar",
          "url" => data["icon"]["url"]
        }

    banner =
      data["image"]["url"] &&
        %{
          "name" => data["image"]["name"] || "banner",
          "url" => data["image"]["url"]
        }

    actor_data = %{
      url: data["id"],
      avatar: avatar,
      banner: banner,
      name: data["name"],
      preferred_username: data["preferredUsername"],
      summary: data["summary"],
      keys: data["publicKey"]["publicKeyPem"],
      inbox_url: data["inbox"],
      outbox_url: data["outbox"],
      following_url: data["following"],
      followers_url: data["followers"],
      shared_inbox_url: data["endpoints"]["sharedInbox"],
      domain: URI.parse(data["id"]).host,
      manually_approves_followers: data["manuallyApprovesFollowers"],
      type: data["type"]
    }

    {:ok, actor_data}
  end

  @doc """
  Return all public activities (events & comments) for an actor
  """
  @spec fetch_public_activities_for_actor(Actor.t(), integer(), integer()) :: map()
  def fetch_public_activities_for_actor(%Actor{} = actor, page \\ 1, limit \\ 10) do
    {:ok, events, total_events} = Events.get_public_events_for_actor(actor, page, limit)
    {:ok, comments, total_comments} = Events.get_public_comments_for_actor(actor, page, limit)

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
      data: event |> Mobilizon.Service.ActivityPub.Converters.Event.model_to_as(),
      local: local
    }
  end

  # Create an activity from a comment
  @spec comment_to_activity(%Comment{}, boolean()) :: Activity.t()
  defp comment_to_activity(%Comment{} = comment, local \\ true) do
    %Activity{
      recipients: ["https://www.w3.org/ns/activitystreams#Public"],
      actor: comment.actor.url,
      data: comment |> Mobilizon.Service.ActivityPub.Converters.Comment.model_to_as(),
      local: local
    }
  end

  #  # Whether the Public audience is in the activity's audience
  #  defp is_public?(activity) do
  #    "https://www.w3.org/ns/activitystreams#Public" in (activity.data["to"] ++
  #                                                         (activity.data["cc"] || []))
  #  end
end
