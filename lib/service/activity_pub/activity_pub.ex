defmodule Eventos.Service.ActivityPub do
  alias Eventos.Events
  alias Eventos.Events.Event
  alias Eventos.Service.ActivityPub.Transmogrifier
  alias Eventos.Service.WebFinger
  alias Eventos.Activity

  alias Eventos.Actors
  alias Eventos.Actors.Actor

  alias Eventos.Service.Federator

  import Logger
  import Eventos.Service.ActivityPub.Utils

  def get_recipients(data) do
    (data["to"] || []) ++ (data["cc"] || [])
  end

  def insert(map, local \\ true) when is_map(map) do
    with map <- lazy_put_activity_defaults(map),
         :ok <- insert_full_object(map) do
      map = Map.put(map, "id", Ecto.UUID.generate())
      activity = %Activity{
          data: map,
          local: local,
          actor: map["actor"],
          recipients: get_recipients(map)
        }

      # Notification.create_notifications(activity)
      #stream_out(activity)
      {:ok, activity}
    else
      %Activity{} = activity -> {:ok, activity}
      error -> {:error, error}
    end
  end

  def fetch_event_from_url(url) do
    if object = Events.get_event_by_url!(url) do
      {:ok, object}
    else
      Logger.info("Fetching #{url} via AP")

      with true <- String.starts_with?(url, "http"),
           {:ok, %{body: body, status_code: code}} when code in 200..299 <-
             HTTPoison.get(
               url,
               [Accept: "application/activity+json"],
               follow_redirect: true,
               timeout: 10000,
               recv_timeout: 20000
             ),
           {:ok, data} <- Jason.decode(body),
           nil <- Events.get_event_by_url!(data["id"]),
           params <- %{
             "type" => "Create",
             "to" => data["to"],
             "cc" => data["cc"],
             "actor" => data["attributedTo"],
             "object" => data
           },
           {:ok, activity} <- Transmogrifier.handle_incoming(params) do
        {:ok, Events.get_event_by_url!(activity.data["object"]["id"])}
      else
        object = %Event{} -> {:ok, object}
                          e -> e
      end
    end
  end

  def create(%{to: to, actor: actor, context: context, object: object} = params) do
    additional = params[:additional] || %{}
    # only accept false as false value
    local = !(params[:local] == false)
    published = params[:published]

    with create_data <-
           make_create_data(
             %{to: to, actor: actor, published: published, context: context, object: object},
             additional
           ),
         {:ok, activity} <- insert(create_data, local),
         :ok <- maybe_federate(activity) do
         # {:ok, actor} <- Actors.increase_event_count(actor) do
      {:ok, activity}
    else
      err ->
        Logger.debug("Something went wrong")
        Logger.debug(inspect err)
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

  def follow(follower, followed, activity_id \\ nil, local \\ true) do
    with data <- make_follow_data(follower, followed, activity_id),
         {:ok, activity} <- insert(data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity}
    end
  end

  def delete(%Event{url: url, organizer_actor: actor} = event, local \\ true) do

    data = %{
      "type" => "Delete",
      "actor" => actor.url,
      "object" => url,
      "to" => [actor.url <> "/followers", "https://www.w3.org/ns/activitystreams#Public"]
    }

    with Events.delete_event(event),
         {:ok, activity} <- insert(data, local),
         :ok <- maybe_federate(activity)
      do
      {:ok, activity}
    end
  end

  def create_public_activities(%Actor{} = actor) do

  end

  def make_actor_from_url(url) do
    with {:ok, data} <- fetch_and_prepare_user_from_url(url) do
      Actors.insert_or_update_actor(data)
    else
      e ->
        Logger.error("Failed to make actor from url")
        Logger.error(inspect e)
        {:error, e}
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
      followers
      |> Enum.map(fn follower -> follower.shared_inbox_url end)
      |> Enum.uniq()

    {:ok, data} = Transmogrifier.prepare_outgoing(activity.data)
    json = Jason.encode!(data)

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
      Eventos.Service.HTTPSignatures.sign(actor, %{host: host, "content-length": byte_size(json)})
    Logger.debug("signature")
    Logger.debug(inspect signature)

    {:ok, response} = HTTPoison.post(
      inbox,
      json,
      [{"Content-Type", "application/activity+json"}, {"signature", signature}],
      hackney: [pool: :default]
    )
    Logger.debug(inspect response)
  end

  def fetch_and_prepare_user_from_url(url) do
    Logger.debug("Fetching and preparing user from url")
    with {:ok, %{status_code: 200, body: body}} <-
           HTTPoison.get(url, [Accept: "application/activity+json"], [follow_redirect: true]),
         {:ok, data} <- Jason.decode(body) do
      user_data_from_user_object(data)
    else
      e -> Logger.error("Could not decode user at fetch #{url}, #{inspect(e)}")
    end
  end

  def user_data_from_user_object(data) do
    Logger.debug("user_data_from_user_object")
    Logger.debug(inspect data)
    avatar =
      data["icon"]["url"] &&
        %{
          "type" => "Image",
          "url" => [%{"href" => data["icon"]["url"]}]
        }

    banner =
      data["image"]["url"] &&
        %{
          "type" => "Image",
          "url" => [%{"href" => data["image"]["url"]}]
        }

    user_data = %{
      url: data["id"],
      info: %{
        "ap_enabled" => true,
        "source_data" => data,
        "banner" => banner
      },
      avatar: avatar,
      name: data["name"],
      preferred_username: data["preferredUsername"],
      follower_address: data["followers"],
      summary: data["summary"],
      public_key: data["publicKey"]["publicKeyPem"],
      inbox_url: data["inbox"],
      outbox_url: data["outbox"],
      following_url: data["following"],
      followers_url: data["followers"],
      shared_inbox_url: data["sharedInbox"],
      domain: URI.parse(data["id"]).host,
      manually_approves_followers: data["manuallyApprovesFollowers"],
      type: data["type"],
    }

    {:ok, user_data}
  end

  @spec fetch_public_activities_for_actor(Actor.t, integer(), integer()) :: list()
  def fetch_public_activities_for_actor(%Actor{} = actor, page \\ 10, limit \\ 1) do
    {:ok, events, total} = Events.get_events_for_actor(actor, page, limit)
    activities = Enum.map(events, fn event ->
      {:ok, activity} = event_to_activity(event)
      activity
    end)
    {activities, total}
  end

  defp event_to_activity(%Event{} = event) do
    activity = %Activity{
      data: event,
      local: true,
      actor: event.organizer_actor.url,
      recipients: ["https://www.w3.org/ns/activitystreams#Public"]
    }

    # Notification.create_notifications(activity)
    #stream_out(activity)
    {:ok, activity}
  end
end
