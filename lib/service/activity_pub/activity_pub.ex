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

  alias Mobilizon.Service.Federator

  require Logger
  import Mobilizon.Service.ActivityPub.Utils

  def get_recipients(data) do
    (data["to"] || []) ++ (data["cc"] || [])
  end

  def insert(map, local \\ true) when is_map(map) do
    Logger.debug("preparing an activity")
    Logger.debug(inspect(map))

    with map <- lazy_put_activity_defaults(map),
         :ok <- insert_full_object(map, local) do
      map = Map.put(map, "id", "#{map["object"].url}/activity")

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

  def fetch_object_from_url(url, :event), do: fetch_event_from_url(url)
  def fetch_object_from_url(url, :note), do: fetch_note_from_url(url)

  @spec fetch_object_from_url(String.t()) :: tuple()
  def fetch_object_from_url(url) do
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
          {:ok, Events.get_comment_from_url!(activity.data["object"]["id"])}
      end
    else
      object = %Event{} -> {:ok, object}
      object = %Comment{} -> {:ok, object}
      e -> {:error, e}
    end
  end

  @spec fetch_object_from_url(String.t()) :: tuple()
  def fetch_event_from_url(url) do
    with nil <- Events.get_event_by_url(url) do
      Logger.info("Fetching #{url} via AP")
      fetch_object_from_url(url)
    else
      %Event{} = comment ->
        {:ok, comment}
    end
  end

  @spec fetch_object_from_url(String.t()) :: tuple()
  def fetch_note_from_url(url) do
    with nil <- Events.get_comment_from_url(url) do
      Logger.info("Fetching #{url} via AP")

      fetch_object_from_url(url)
    else
      %Comment{} = comment ->
        {:ok, comment}
    end
  end

  def create(%{to: to, actor: actor, object: object, context: context} = params) do
    Logger.debug("creating an activity")
    additional = params[:additional] || %{}
    # only accept false as false value
    local = !(params[:local] == false)
    published = params[:published]

    with create_data <-
           make_create_data(
             %{to: to, actor: actor, published: published, object: object, context: context},
             additional
           ),
         {:ok, activity} <- insert(create_data, local),
         :ok <- maybe_federate(activity) do
      # {:ok, actor} <- Actors.increase_event_count(actor) do
      {:ok, activity}
    else
      err ->
        Logger.debug("Something went wrong")
        Logger.debug(inspect(err))
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

  def follow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with data <- make_follow_data(follower, followed, activity_id),
         {:ok, activity} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
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

  def create_public_activities(%Actor{} = actor) do
  end

  def make_actor_from_url(url) do
    with {:ok, data} <- fetch_and_prepare_user_from_url(url) do
      Actors.insert_or_update_actor(data)
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

  @spec find_or_make_actor_from_nickname(String.t()) :: tuple()
  def find_or_make_actor_from_nickname(nickname) do
    with %Actor{} = actor <- Actors.get_actor_by_name(nickname) do
      {:ok, actor}
    else
      nil -> make_actor_from_nickname(nickname)
    end
  end

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
        {:ok, followers} = Actor.get_followers(actor)
        followers |> Enum.filter(fn follower -> is_nil(follower.domain) end)
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
    host = URI.parse(inbox).host

    signature =
      Mobilizon.Service.HTTPSignatures.sign(actor, %{
        host: host,
        "content-length": byte_size(json)
      })

    Logger.debug("signature")
    Logger.debug(inspect(signature))

    Logger.debug("body json")
    Logger.debug(inspect(json))

    {:ok, response} =
      HTTPoison.post(
        inbox,
        json,
        [{"Content-Type", "application/activity+json"}, {"signature", signature}],
        hackney: [pool: :default]
      )

    Logger.debug(inspect(response))
  end

  def fetch_and_prepare_user_from_url(url) do
    Logger.debug("Fetching and preparing user from url")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, [Accept: "application/activity+json"], follow_redirect: true),
         {:ok, data} <- Jason.decode(body) do
      user_data_from_user_object(data)
    else
      # User is gone, probably deleted
      {:ok, %HTTPoison.Response{status_code: 410}} ->
        {:error, :actor_deleted}

      e ->
        Logger.error("Could not decode user at fetch #{url}, #{inspect(e)}")
        e
    end
  end

  def user_data_from_user_object(data) do
    user_data = %{
      url: data["id"],
      info: %{
        "ap_enabled" => true,
        "source_data" => data
      },
      avatar_url: data["icon"]["url"],
      banner_url: data["image"]["url"],
      name: data["name"],
      preferred_username: data["preferredUsername"],
      follower_address: data["followers"],
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

    Logger.debug("user_data_from_user_object")
    Logger.debug(inspect(user_data))

    {:ok, user_data}
  end

  @spec fetch_public_activities_for_actor(Actor.t(), integer(), integer()) :: list()
  def fetch_public_activities_for_actor(%Actor{} = actor, page \\ 1, limit \\ 10) do
    case actor.type do
      :Person ->
        {:ok, events, total} = Events.get_events_for_actor(actor, page, limit)
        {:ok, comments, total} = Events.get_comments_for_actor(actor, page, limit)

        event_activities =
          Enum.map(events, fn event ->
            {:ok, activity} = event_to_activity(event)
            activity
          end)

        comment_activities =
          Enum.map(comments, fn comment ->
            {:ok, activity} = comment_to_activity(comment)
            activity
          end)

        activities = event_activities ++ comment_activities

        {activities, total}

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

  defp event_to_activity(%Event{} = event, local \\ true) do
    activity = %Activity{
      type: :Event,
      data: event,
      local: local,
      actor: event.organizer_actor.url,
      recipients: ["https://www.w3.org/ns/activitystreams#Public"]
    }

    # Notification.create_notifications(activity)
    # stream_out(activity)
    {:ok, activity}
  end

  defp comment_to_activity(%Comment{} = comment, local \\ true) do
    activity = %Activity{
      type: :Comment,
      data: comment,
      local: local,
      actor: comment.actor.url,
      recipients: ["https://www.w3.org/ns/activitystreams#Public"]
    }

    # Notification.create_notifications(activity)
    # stream_out(activity)
    {:ok, activity}
  end

  defp ical_event_to_activity(%ExIcal.Event{} = ical_event, %Actor{} = actor, source) do
    # Logger.debug(inspect ical_event)
    # TODO : refactor me !
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
end
