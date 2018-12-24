# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.ActivityPub do
  @moduledoc """
  # ActivityPub

  Every ActivityPub method
  """

  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Category, Comment}
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

  TODO: Rename me
  """
  @spec insert(map(), boolean()) :: {:ok, %Activity{}} | {:error, any()}
  def insert(map, local \\ true) when is_map(map) do
    with map <- lazy_put_activity_defaults(map),
         :ok <- insert_full_object(map) do
      object_id =
        cond do
          is_map(map["object"]) ->
            map["object"]["id"]

          is_binary(map["object"]) ->
            map["id"]
        end

      map = if local, do: Map.put(map, "id", "#{object_id}/activity"), else: map

      activity = %Activity{
        data: map,
        local: local,
        actor: map["actor"],
        recipients: get_recipients(map)
      }

      # Notification.create_notifications(activity)
      # stream_out(activity)
      {:ok, activity}
    else
      %Activity{} = activity -> {:ok, activity}
      error -> {:error, error}
    end
  end

  @doc """
  Fetch an object from an URL, from our local database of events and comments, then eventually remote
  """
  @spec fetch_object_from_url(String.t()) :: {:ok, %Event{}} | {:ok, %Comment{}} | {:error, any()}
  def fetch_object_from_url(url) do
    Logger.info("Fetching object from url #{url}")

    with true <- String.starts_with?(url, "http"),
         nil <- Events.get_event_by_url(url),
         nil <- Events.get_comment_from_url(url),
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

        other ->
          {:error, other}
      end
    else
      %Event{url: event_url} -> {:ok, Events.get_event_by_url!(event_url)}
      %Comment{url: comment_url} -> {:ok, Events.get_comment_full_from_url!(comment_url)}
      e -> {:error, e}
    end
  end

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
         {:ok, activity} <- insert(create_data, local),
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
         {:ok, activity} <- insert(data, local),
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
         {:ok, activity} <- insert(data, local),
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
  #        {:ok, activity} <- insert(like_data, local),
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
  #        {:ok, unlike_activity} <- insert(unlike_data, local),
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
  #        {:ok, activity} <- insert(announce_data, local),
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
  #        {:ok, unannounce_activity} <- insert(unannounce_data, local),
  #        :ok <- maybe_federate(unannounce_activity),
  #        {:ok, _activity} <- Repo.delete(announce_activity),
  #        {:ok, object} <- remove_announce_from_object(announce_activity, object) do
  #     {:ok, unannounce_activity, object}
  #   else
  #     _e -> {:ok, object}
  #   end
  # end

  def follow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{} = follow} <- Actor.follow(followed, follower, true),
         activity_follow_id <- activity_id || Follower.url(follow),
         data <- make_follow_data(followed, follower, activity_follow_id),
         {:ok, activity} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    else
      {err, _} when err in [:already_following, :suspended] ->
        {:error, err}
    end
  end

  @spec unfollow(Actor.t(), Actor.t(), String.t(), boolean()) :: {:ok, map()} | any()
  def unfollow(%Actor{} = followed, %Actor{} = follower, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{id: follow_id}} <- Actor.unfollow(followed, follower),
         # We recreate the follow activity
         data <- make_follow_data(followed, follower, follow_id),
         {:ok, follow_activity} <- insert(data, local),
         unfollow_data <- make_unfollow_data(follower, followed, follow_activity, activity_id),
         {:ok, activity} <- insert(unfollow_data, local),
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

    with Events.delete_event(event),
         {:ok, activity} <- insert(data, local),
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

    with Events.delete_comment(comment),
         {:ok, activity} <- insert(data, local),
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

    with Actors.delete_actor(actor),
         {:ok, activity} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  @doc """
  Create an actor locally by it's URL (AP ID)
  """
  @spec make_actor_from_url(String.t(), boolean()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_url(url, preload \\ false) do
    with {:ok, data} <- fetch_and_prepare_actor_from_url(url) do
      Actors.insert_or_update_actor(data, preload)
    else
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
  Find an actor in our local database or call Webfinger to find what's its AP ID is and then fetch it
  """
  @spec find_or_make_actor_from_nickname(String.t(), atom() | nil) :: tuple()
  def find_or_make_actor_from_nickname(nickname, type \\ nil) do
    with %Actor{} = actor <- Actors.get_actor_by_name(nickname, type) do
      {:ok, actor}
    else
      nil -> make_actor_from_nickname(nickname)
    end
  end

  @spec find_or_make_person_from_nickname(String.t()) :: tuple()
  def find_or_make_person_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Person)

  @spec find_or_make_group_from_nickname(String.t()) :: tuple()
  def find_or_make_group_from_nickname(nick), do: find_or_make_actor_from_nickname(nick, :Group)

  @doc """
  Create an actor inside our database from username, using Webfinger to find out it's AP ID and then fetch it
  """
  @spec make_actor_from_nickname(String.t()) :: {:ok, %Actor{}} | {:error, any()}
  def make_actor_from_nickname(nickname) do
    with {:ok, %{"url" => url}} when not is_nil(url) <- WebFinger.finger(nickname) do
      make_actor_from_url(url)
    else
      _e -> {:error, "No ActivityPub URL found in WebFinger"}
    end
  end

  def publish(actor, activity) do
    Logger.debug("Publishing an activity")

    followers =
      if actor.followers_url in activity.recipients do
        Actor.get_followers(actor) |> Enum.filter(fn follower -> is_nil(follower.domain) end)
      else
        []
      end

    remote_inboxes =
      (remote_actors(activity) ++ followers)
      |> Enum.map(fn follower -> follower.shared_inbox_url end)
      |> Enum.uniq()

    {:ok, data} = Transmogrifier.prepare_outgoing(activity.data)
    json = Jason.encode!(data)
    Logger.debug("Remote inboxes are : #{inspect(remote_inboxes)}")

    Enum.each(remote_inboxes, fn inbox ->
      Federator.enqueue(:publish_single_ap, %{
        inbox: inbox,
        json: json,
        actor: actor,
        id: activity.data["id"]
      })
    end)
  end

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

  # Fetching a remote actor's informations through it's AP ID
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
  """
  @spec actor_data_from_actor_object(map()) :: {:ok, map()}
  def actor_data_from_actor_object(data) when is_map(data) do
    actor_data = %{
      url: data["id"],
      avatar_url: data["icon"]["url"],
      banner_url: data["image"]["url"],
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
  @spec fetch_public_activities_for_actor(Actor.t(), integer(), integer()) :: {list(), integer()}
  def fetch_public_activities_for_actor(actor, page \\ nil, limit \\ nil)

  def fetch_public_activities_for_actor(%Actor{} = actor, page, limit) do
    case actor.type do
      :Person ->
        {:ok, events, total_events} = Events.get_events_for_actor(actor, page, limit)
        {:ok, comments, total_comments} = Events.get_comments_for_actor(actor, page, limit)

        event_activities = Enum.map(events, &event_to_activity/1)

        comment_activities = Enum.map(comments, &comment_to_activity/1)

        activities = event_activities ++ comment_activities

        {activities, total_events + total_comments}

      :Service ->
        bot = Actors.get_bot_by_actor(actor)

        case bot.type do
          "ics" ->
            {:ok, %HTTPoison.Response{body: body} = _resp} = HTTPoison.get(bot.source)

            ical_events =
              body
              |> ExIcal.parse()
              |> ExIcal.by_range(DateTime.utc_now(), DateTime.utc_now() |> Timex.shift(years: 1))

            activities =
              ical_events
              |> Enum.chunk_every(limit)
              |> Enum.at(page - 1)
              |> Enum.map(fn event ->
                {:ok, activity} = ical_event_to_activity(event, actor, bot.source)
                activity
              end)

            {activities, length(ical_events)}
        end
    end
  end

  # Create an activity from an event
  @spec event_to_activity(%Event{}, boolean()) :: Activity.t()
  defp event_to_activity(%Event{} = event, local \\ true) do
    %Activity{
      recipients: ["https://www.w3.org/ns/activitystreams#Public"],
      actor: event.organizer_actor.url,
      data: event |> make_event_data,
      local: local
    }
  end

  # Create an activity from a comment
  @spec comment_to_activity(%Comment{}, boolean()) :: Activity.t()
  def comment_to_activity(%Comment{} = comment, local \\ true) do
    %Activity{
      recipients: ["https://www.w3.org/ns/activitystreams#Public"],
      actor: comment.actor.url,
      data: comment |> make_comment_data,
      local: local
    }
  end

  defp ical_event_to_activity(%ExIcal.Event{} = ical_event, %Actor{} = actor, _source) do
    # Logger.debug(inspect ical_event)
    # TODO : refactor me !
    # TODO : also, there should be a form of cache that allows this to be more efficient
    category =
      if is_nil(ical_event.categories) do
        nil
      else
        ical_category = ical_event.categories |> hd() |> String.downcase()

        case ical_category |> Events.get_category_by_title() do
          nil ->
            case Events.create_category(%{"title" => ical_category}) do
              {:ok, %Category{} = category} -> category
              _ -> nil
            end

          category ->
            category
        end
      end

    {:ok, event} =
      Events.create_event(%{
        begins_on: ical_event.start,
        ends_on: ical_event.end,
        inserted_at: ical_event.stamp,
        updated_at: ical_event.stamp,
        description: ical_event.description |> sanitize_ical_event_strings,
        title: ical_event.summary |> sanitize_ical_event_strings,
        organizer_actor: actor,
        category: category
      })

    event_to_activity(event, false)
  end

  defp sanitize_ical_event_strings(string) when is_binary(string) do
    string
    |> String.replace(~s"\r\n", "")
    |> String.replace(~s"\\,", ",")
  end

  defp sanitize_ical_event_strings(nil) do
    nil
  end

  def is_public?(activity) do
    "https://www.w3.org/ns/activitystreams#Public" in (activity.data["to"] ++
                                                         (activity.data["cc"] || []))
  end
end
