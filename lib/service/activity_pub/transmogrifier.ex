# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/transmogrifier.ex

defmodule Mobilizon.Service.ActivityPub.Transmogrifier do
  @moduledoc """
  A module to handle coding from internal to wire ActivityPub and back.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Events
  alias Mobilizon.Events.{Comment, Event, Participant}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.{Activity, Converter, Convertible, Utils}
  alias MobilizonWeb.Email.Participation

  import Mobilizon.Service.ActivityPub.Utils

  require Logger

  def get_actor(%{"actor" => actor}) when is_binary(actor) do
    actor
  end

  def get_actor(%{"actor" => actor}) when is_list(actor) do
    if is_binary(Enum.at(actor, 0)) do
      Enum.at(actor, 0)
    else
      actor
      |> Enum.find(fn %{"type" => type} -> type in ["Person", "Service", "Application"] end)
      |> Map.get("id")
    end
  end

  def get_actor(%{"actor" => %{"id" => id}}) when is_bitstring(id) do
    id
  end

  def get_actor(%{"actor" => nil, "attributedTo" => actor}) when not is_nil(actor) do
    get_actor(%{"actor" => actor})
  end

  @doc """
  Modifies an incoming AP object (mastodon format) to our internal format.
  """
  def fix_object(object) do
    object
    |> Map.put("actor", object["attributedTo"])
    |> fix_attachments
    |> fix_in_reply_to

    # |> fix_tag
  end

  def fix_in_reply_to(%{"inReplyTo" => in_reply_to} = object)
      when not is_nil(in_reply_to) and is_bitstring(in_reply_to) do
    in_reply_to |> do_fix_in_reply_to(object)
  end

  def fix_in_reply_to(%{"inReplyTo" => in_reply_to} = object)
      when not is_nil(in_reply_to) and is_map(in_reply_to) do
    if is_bitstring(in_reply_to["id"]) do
      in_reply_to["id"] |> do_fix_in_reply_to(object)
    end
  end

  def fix_in_reply_to(%{"inReplyTo" => in_reply_to} = object)
      when not is_nil(in_reply_to) and is_list(in_reply_to) do
    if is_bitstring(Enum.at(in_reply_to, 0)) do
      in_reply_to |> Enum.at(0) |> do_fix_in_reply_to(object)
    end
  end

  def fix_in_reply_to(%{"inReplyTo" => in_reply_to} = object)
      when not is_nil(in_reply_to) do
    Logger.warn("inReplyTo ID seem incorrect: #{inspect(in_reply_to)}")
    do_fix_in_reply_to("", object)
  end

  def fix_in_reply_to(object), do: object

  def do_fix_in_reply_to(in_reply_to_id, object) do
    case fetch_obj_helper(in_reply_to_id) do
      {:ok, replied_object} ->
        object
        |> Map.put("inReplyTo", replied_object.url)

      {:error, {:error, :not_supported}} ->
        Logger.info("Object reply origin has not a supported type")
        object

      e ->
        Logger.warn("Couldn't fetch #{in_reply_to_id} #{inspect(e)}")
        object
    end
  end

  def fix_attachments(object) do
    attachments =
      (object["attachment"] || [])
      |> Enum.map(fn data ->
        url = [%{"type" => "Link", "mediaType" => data["mediaType"], "href" => data["url"]}]
        Map.put(data, "url", url)
      end)

    object
    |> Map.put("attachment", attachments)
  end

  def fix_tag(object) do
    tags =
      (object["tag"] || [])
      |> Enum.filter(fn data -> data["type"] == "Hashtag" and data["name"] end)
      |> Enum.map(fn data -> String.slice(data["name"], 1..-1) end)

    combined = (object["tag"] || []) ++ tags

    object
    |> Map.put("tag", combined)
  end

  def handle_incoming(%{"id" => nil}), do: :error
  def handle_incoming(%{"id" => ""}), do: :error

  def handle_incoming(%{"type" => "Flag"} = data) do
    with params <- Converter.Flag.as_to_model(data) do
      params = %{
        reporter_url: params["reporter"].url,
        reported_actor_url: params["reported"].url,
        comments_url: params["comments"] |> Enum.map(& &1.url),
        content: params["content"] || "",
        additional: %{
          "cc" => [params["reported"].url]
        }
      }

      ActivityPub.flag(params)
    end
  end

  @doc """
  Handles a `Create` activity for `Note` (comments) objects

  The following actions are performed
  * Fetch the author of the activity
  * Convert the ActivityStream data to the comment model format (it also finds and inserts tags)
  * Get (by it's URL) or create the comment with this data
  * Insert eventual mentions in the database
  * Convert the comment back in ActivityStreams data
  * Wrap this data back into a `Create` activity
  * Return the activity and the comment object
  """
  def handle_incoming(%{"type" => "Create", "object" => %{"type" => "Note"} = object}) do
    Logger.info("Handle incoming to create notes")

    with {:ok, object_data} <-
           object |> fix_object() |> Converter.Comment.as_to_model_data(),
         {:existing_comment, {:error, :comment_not_found}} <-
           {:existing_comment, Events.get_comment_from_url_with_preload(object_data.url)},
         {:ok, %Activity{} = activity, %Comment{} = comment} <-
           ActivityPub.create(:comment, object_data, false) do
      {:ok, activity, comment}
    else
      {:existing_comment, {:ok, %Comment{} = comment}} ->
        {:ok, nil, comment}
    end
  end

  @doc """
  Handles a `Create` activity for `Event` objects

  The following actions are performed
  * Fetch the author of the activity
  * Convert the ActivityStream data to the event model format (it also finds and inserts tags)
  * Get (by it's URL) or create the event with this data
  * Insert eventual mentions in the database
  * Convert the event back in ActivityStreams data
  * Wrap this data back into a `Create` activity
  * Return the activity and the event object
  """
  def handle_incoming(%{"type" => "Create", "object" => %{"type" => "Event"} = object}) do
    Logger.info("Handle incoming to create event")

    with {:ok, object_data} <-
           object |> fix_object() |> Converter.Event.as_to_model_data(),
         {:existing_event, nil} <- {:existing_event, Events.get_event_by_url(object_data.url)},
         {:ok, %Activity{} = activity, %Event{} = event} <-
           ActivityPub.create(:event, object_data, false) do
      {:ok, activity, event}
    else
      {:existing_event, %Event{} = event} -> {:ok, nil, event}
    end
  end

  def handle_incoming(
        %{"type" => "Follow", "object" => followed, "actor" => follower, "id" => id} = _data
      ) do
    with {:ok, %Actor{} = followed} <- ActivityPub.get_or_fetch_actor_by_url(followed, true),
         {:ok, %Actor{} = follower} <- ActivityPub.get_or_fetch_actor_by_url(follower),
         {:ok, activity, object} <- ActivityPub.follow(follower, followed, id, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.warn("Unable to handle Follow activity #{inspect(e)}")
        :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Accept",
          "object" => accepted_object,
          "actor" => _actor,
          "id" => id
        } = data
      ) do
    with actor_url <- get_actor(data),
         {:ok, %Actor{} = actor} <- ActivityPub.get_or_fetch_actor_by_url(actor_url),
         {:object_not_found, {:ok, %Activity{} = activity, object}} <-
           {:object_not_found,
            do_handle_incoming_accept_following(accepted_object, actor) ||
              do_handle_incoming_accept_join(accepted_object, actor)} do
      {:ok, activity, object}
    else
      {:object_not_found, nil} ->
        Logger.warn(
          "Unable to process Accept activity #{inspect(id)}. Object #{inspect(accepted_object)} wasn't found."
        )

        :error

      e ->
        Logger.warn(
          "Unable to process Accept activity #{inspect(id)} for object #{inspect(accepted_object)} only returned #{
            inspect(e)
          }"
        )

        :error
    end
  end

  def handle_incoming(
        %{"type" => "Reject", "object" => rejected_object, "actor" => _actor, "id" => id} = data
      ) do
    with actor_url <- get_actor(data),
         {:ok, %Actor{} = actor} <- ActivityPub.get_or_fetch_actor_by_url(actor_url),
         {:object_not_found, {:ok, activity, object}} <-
           {:object_not_found,
            do_handle_incoming_reject_following(rejected_object, actor) ||
              do_handle_incoming_reject_join(rejected_object, actor)} do
      {:ok, activity, object}
    else
      {:object_not_found, nil} ->
        Logger.warn(
          "Unable to process Reject activity #{inspect(id)}. Object #{inspect(rejected_object)} wasn't found."
        )

        :error

      e ->
        Logger.warn(
          "Unable to process Reject activity #{inspect(id)} for object #{inspect(rejected_object)} only returned #{
            inspect(e)
          }"
        )

        :error
    end
  end

  #
  #  def handle_incoming(
  #        %{"type" => "Like", "object" => object_id, "actor" => actor, "id" => id} = data
  #      ) do
  #    with %User{} = actor <- User.get_or_fetch_by_ap_id(actor),
  #         {:ok, object} <-
  #           fetch_obj_helper(object_id) || ActivityPub.fetch_object_from_id(object_id),
  #         {:ok, activity, object} <- ActivityPub.like(actor, object, id, false) do
  #      {:ok, activity}
  #    else
  #      _e -> :error
  #    end
  #  end
  # #
  def handle_incoming(
        %{"type" => "Announce", "object" => object_id, "actor" => _actor, "id" => _id} = data
      ) do
    with actor <- get_actor(data),
         # TODO: Is the following line useful?
         {:ok, %Actor{} = _actor} <- ActivityPub.get_or_fetch_actor_by_url(actor),
         :ok <- Logger.debug("Fetching contained object"),
         {:ok, object} <- fetch_obj_helper_as_activity_streams(object_id),
         :ok <- Logger.debug("Handling contained object"),
         create_data <-
           make_create_data(object),
         :ok <- Logger.debug(inspect(object)),
         {:ok, _activity, object} <- handle_incoming(create_data),
         :ok <- Logger.debug("Finished processing contained object"),
         {:ok, activity} <- ActivityPub.create_activity(data, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(%{
        "type" => "Update",
        "object" => %{"type" => object_type} = object,
        "actor" => _actor_id
      })
      when object_type in ["Person", "Group", "Application", "Service", "Organization"] do
    with {:ok, %Actor{} = old_actor} <- Actors.get_actor_by_url(object["id"]),
         {:ok, object_data} <-
           object |> fix_object() |> Converter.Actor.as_to_model_data(),
         {:ok, %Activity{} = activity, %Actor{} = new_actor} <-
           ActivityPub.update(:actor, old_actor, object_data, false) do
      {:ok, activity, new_actor}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => "Event"} = object, "actor" => _actor} =
          _update
      ) do
    with %Event{} = old_event <-
           Events.get_event_by_url(object["id"]),
         {:ok, object_data} <-
           object |> fix_object() |> Converter.Event.as_to_model_data(),
         {:ok, %Activity{} = activity, %Event{} = new_event} <-
           ActivityPub.update(:event, old_event, object_data, false) do
      {:ok, activity, new_event}
    else
      _e ->
        :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Undo",
          "object" => %{
            "type" => "Announce",
            "object" => object_id,
            "id" => cancelled_activity_id
          },
          "actor" => _actor,
          "id" => id
        } = data
      ) do
    with actor <- get_actor(data),
         {:ok, %Actor{} = actor} <- ActivityPub.get_or_fetch_actor_by_url(actor),
         {:ok, object} <- fetch_obj_helper_as_activity_streams(object_id),
         {:ok, activity, object} <-
           ActivityPub.unannounce(actor, object, id, cancelled_activity_id, false) do
      {:ok, activity, object}
    else
      _e -> :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Undo",
          "object" => %{"type" => "Follow", "object" => followed},
          "actor" => follower,
          "id" => id
        } = _data
      ) do
    with {:ok, %Actor{domain: nil} = followed} <- Actors.get_actor_by_url(followed),
         {:ok, %Actor{} = follower} <- Actors.get_actor_by_url(follower),
         {:ok, activity, object} <- ActivityPub.unfollow(follower, followed, id, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  # TODO: We presently assume that any actor on the same origin domain as the object being
  # deleted has the rights to delete that object.  A better way to validate whether or not
  # the object should be deleted is to refetch the object URI, which should return either
  # an error or a tombstone.  This would allow us to verify that a deletion actually took
  # place.
  def handle_incoming(
        %{"type" => "Delete", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    object_id = Utils.get_url(object)

    with actor <- get_actor(data),
         {:ok, %Actor{url: _actor_url}} <- Actors.get_actor_by_url(actor),
         {:ok, object} <- fetch_obj_helper(object_id),
         #  TODO : Validate that DELETE comes indeed form right domain (see above)
         #  :ok <- contain_origin(actor_url, object.data),
         {:ok, activity, object} <- ActivityPub.delete(object, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Join", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    with actor <- get_actor(data),
         {:ok, %Actor{url: _actor_url} = actor} <- Actors.get_actor_by_url(actor),
         {:ok, object} <- fetch_obj_helper(object),
         {:ok, activity, object} <- ActivityPub.join(object, actor, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Leave", "object" => object, "actor" => actor, "id" => _id} = data
      ) do
    with actor <- get_actor(data),
         {:ok, %Actor{} = actor} <- Actors.get_actor_by_url(actor),
         {:ok, object} <- fetch_obj_helper(object),
         {:ok, activity, object} <- ActivityPub.leave(object, actor, false) do
      {:ok, activity, object}
    else
      {:only_organizer, true} ->
        Logger.warn(
          "Actor #{inspect(actor)} tried to leave event #{inspect(object)} but it was the only organizer so we didn't detach it"
        )

        :error

      _e ->
        :error
    end
  end

  #
  #  # TODO
  #  # Accept
  #  # Undo
  #
  # def handle_incoming(
  #       %{
  #         "type" => "Undo",
  #         "object" => %{"type" => "Like", "object" => object_id},
  #         "actor" => _actor,
  #         "id" => id
  #       } = data
  #     ) do
  #   with actor <- get_actor(data),
  #        %Actor{} = actor <- ActivityPub.get_or_fetch_actor_by_url(actor),
  #        {:ok, object} <- fetch_obj_helper(object_id) || fetch_obj_helper(object_id),
  #        {:ok, activity, _, _} <- ActivityPub.unlike(actor, object, id, false) do
  #     {:ok, activity}
  #   else
  #     _e -> :error
  #   end
  # end

  def handle_incoming(_) do
    Logger.info("Handing something not supported")
    {:error, :not_supported}
  end

  @doc """
  Handle incoming `Accept` activities wrapping a `Follow` activity
  """
  def do_handle_incoming_accept_following(follow_object, %Actor{} = actor) do
    with {:follow, {:ok, %Follower{approved: false, target_actor: followed} = follow}} <-
           {:follow, get_follow(follow_object)},
         {:same_actor, true} <- {:same_actor, actor.id == followed.id},
         {:ok, %Activity{} = activity, %Follower{approved: true} = follow} <-
           ActivityPub.accept(
             :follow,
             follow,
             %{approved: true},
             false
           ) do
      {:ok, activity, follow}
    else
      {:follow, _} ->
        Logger.debug(
          "Tried to handle an Accept activity but it's not containing a Follow activity"
        )

        nil

      {:same_actor} ->
        {:error, "Actor who accepted the follow wasn't the target. Quite odd."}

      {:ok, %Follower{approved: true} = _follow} ->
        {:error, "Follow already accepted"}
    end
  end

  @doc """
  Handle incoming `Reject` activities wrapping a `Follow` activity
  """
  def do_handle_incoming_reject_following(follow_object, %Actor{} = actor) do
    with {:follow,
          {:ok,
           %Follower{approved: false, actor: follower, id: follow_id, target_actor: followed} =
             follow}} <-
           {:follow, get_follow(follow_object)},
         {:same_actor, true} <- {:same_actor, actor.id == followed.id},
         {:ok, activity, _} <-
           ActivityPub.reject(
             %{
               to: [follower.url],
               actor: actor.url,
               object: follow_object,
               local: false
             },
             "#{MobilizonWeb.Endpoint.url()}/reject/follow/#{follow_id}"
           ),
         {:ok, %Follower{}} <- Actors.delete_follower(follow) do
      {:ok, activity, follow}
    else
      {:follow, _} ->
        Logger.debug(
          "Tried to handle a Reject activity but it's not containing a Follow activity"
        )

        nil

      {:same_actor} ->
        {:error, "Actor who rejected the follow wasn't the target. Quite odd."}

      {:ok, %Follower{approved: true} = _follow} ->
        {:error, "Follow already accepted"}
    end
  end

  # Handle incoming `Accept` activities wrapping a `Join` activity on an event
  defp do_handle_incoming_accept_join(join_object, %Actor{} = actor_accepting) do
    with {:join_event, {:ok, %Participant{role: :not_approved, event: event} = participant}} <-
           {:join_event, get_participant(join_object)},
         # TODO: The actor that accepts the Join activity may another one that the event organizer ?
         # Or maybe for groups it's the group that sends the Accept activity
         {:same_actor, true} <- {:same_actor, actor_accepting.id == event.organizer_actor_id},
         {:ok, %Activity{} = activity, %Participant{role: :participant} = participant} <-
           ActivityPub.accept(
             :join,
             participant,
             %{role: :participant},
             false
           ),
         :ok <-
           Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:join_event, {:ok, %Participant{role: :participant}}} ->
        Logger.debug(
          "Tried to handle an Accept activity on a Join activity with a event object but the participant is already validated"
        )

        nil

      {:join_event, _err} ->
        Logger.debug(
          "Tried to handle an Accept activity but it's not containing a Join activity on a event"
        )

        nil

      {:same_actor} ->
        {:error, "Actor who accepted the join wasn't the event organizer. Quite odd."}

      {:ok, %Participant{role: :participant} = _follow} ->
        {:error, "Participant"}
    end
  end

  # Handle incoming `Reject` activities wrapping a `Join` activity on an event
  defp do_handle_incoming_reject_join(join_object, %Actor{} = actor_accepting) do
    with {:join_event,
          {:ok,
           %Participant{role: :not_approved, actor: actor, id: join_id, event: event} =
             participant}} <-
           {:join_event, get_participant(join_object)},
         # TODO: The actor that accepts the Join activity may another one that the event organizer ?
         # Or maybe for groups it's the group that sends the Accept activity
         {:same_actor, true} <- {:same_actor, actor_accepting.id == event.organizer_actor_id},
         {:ok, activity, _} <-
           ActivityPub.reject(
             %{
               to: [actor.url],
               actor: actor_accepting.url,
               object: join_object,
               local: false
             },
             "#{MobilizonWeb.Endpoint.url()}/reject/join/#{join_id}"
           ),
         {:ok, %Participant{role: :rejected} = participant} <-
           Events.update_participant(participant, %{"role" => :rejected}),
         :ok <- Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:join_event, {:ok, %Participant{role: :participant}}} ->
        Logger.debug(
          "Tried to handle an Reject activity on a Join activity with a event object but the participant is already validated"
        )

        nil

      {:join_event, _err} ->
        Logger.debug(
          "Tried to handle an Reject activity but it's not containing a Join activity on a event"
        )

        nil

      {:same_actor} ->
        {:error, "Actor who rejected the join wasn't the event organizer. Quite odd."}

      {:ok, %Participant{role: :participant} = _follow} ->
        {:error, "Participant"}
    end
  end

  # TODO: Add do_handle_incoming_accept_join/1 on Groups

  defp get_follow(follow_object) do
    with follow_object_id when not is_nil(follow_object_id) <- Utils.get_url(follow_object),
         {:not_found, %Follower{} = follow} <-
           {:not_found, Actors.get_follower_by_url(follow_object_id)} do
      {:ok, follow}
    else
      {:not_found, _err} ->
        {:error, "Follow URL not found"}

      _ ->
        {:error, "ActivityPub ID not found in Accept Follow object"}
    end
  end

  defp get_participant(join_object) do
    with join_object_id when not is_nil(join_object_id) <- Utils.get_url(join_object),
         {:not_found, %Participant{} = participant} <-
           {:not_found, Events.get_participant_by_url(join_object_id)} do
      {:ok, participant}
    else
      {:not_found, _err} ->
        {:error, "Participant URL not found"}

      _ ->
        {:error, "ActivityPub ID not found in Accept Join object"}
    end
  end

  def set_reply_to_uri(%{"inReplyTo" => in_reply_to} = object) do
    with false <- String.starts_with?(in_reply_to, "http"),
         {:ok, replied_to_object} <- fetch_obj_helper(in_reply_to) do
      Map.put(object, "inReplyTo", replied_to_object["external_url"] || in_reply_to)
    else
      _e -> object
    end
  end

  def set_reply_to_uri(obj), do: obj
  #
  #  # Prepares the object of an outgoing create activity.
  def prepare_object(object) do
    object
    #    |> set_sensitive
    # |> add_hashtags
    |> add_mention_tags
    #    |> add_emoji_tags
    |> add_attributed_to
    #    |> prepare_attachments
    |> set_reply_to_uri
  end

  @doc """
  internal -> Mastodon
  """
  def prepare_outgoing(%{"type" => "Create", "object" => %{"type" => "Note"} = object} = data) do
    Logger.debug("Prepare outgoing for a note creation")

    object =
      object
      |> prepare_object

    data =
      data
      |> Map.put("object", object)
      |> Map.merge(Utils.make_json_ld_header())

    Logger.debug("Finished prepare outgoing for a note creation")

    {:ok, data}
  end

  def prepare_outgoing(%{"type" => _type} = data) do
    data =
      data
      |> Map.merge(Utils.make_json_ld_header())

    {:ok, data}
  end

  # def prepare_outgoing(%Event{} = event) do
  #   event =
  #     event
  #     |> Map.from_struct()
  #     |> Map.drop([:__meta__])
  #     |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
  #     |> prepare_object

  #   {:ok, event}
  # end

  # def prepare_outgoing(%Comment{} = comment) do
  #   comment =
  #     comment
  #     |> Map.from_struct()
  #     |> Map.drop([:__meta__])
  #     |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
  #     |> prepare_object

  #   {:ok, comment}
  # end

  #
  #  def maybe_fix_object_url(data) do
  #    if is_binary(data["object"]) and not String.starts_with?(data["object"], "http") do
  #      case ActivityPub.fetch_object_from_id(data["object"]) do
  #        {:ok, relative_object} ->
  #          if relative_object.data["external_url"] do
  #            data =
  #              data
  #              |> Map.put("object", relative_object.data["external_url"])
  #          else
  #            data
  #          end
  #
  #        e ->
  #          Logger.error("Couldn't fetch #{data["object"]} #{inspect(e)}")
  #          data
  #      end
  #    else
  #      data
  #    end
  #  end
  #

  def add_hashtags(object) do
    tags =
      (object["tag"] || [])
      |> Enum.map(fn tag ->
        %{
          "href" => MobilizonWeb.Endpoint.url() <> "/tags/#{tag}",
          "name" => "##{tag}",
          "type" => "Hashtag"
        }
      end)

    object
    |> Map.put("tag", tags)
  end

  def add_mention_tags(object) do
    Logger.debug("add mention tags")
    Logger.debug(inspect(object))

    recipients =
      (object["to"] ++ (object["cc"] || [])) -- ["https://www.w3.org/ns/activitystreams#Public"]

    mentions =
      recipients
      |> Enum.filter(& &1)
      |> Enum.map(fn url ->
        case Actors.get_actor_by_url(url) do
          {:ok, actor} -> actor
          _ -> nil
        end
      end)
      |> Enum.filter(& &1)
      |> Enum.map(fn actor ->
        %{
          "type" => "Mention",
          "href" => actor.url,
          "name" => "@#{Actor.preferred_username_and_domain(actor)}"
        }
      end)

    tags = object["tag"] || []

    object
    |> Map.put("tag", tags ++ mentions)
  end

  #
  #  # TODO: we should probably send mtime instead of unix epoch time for updated
  #  def add_emoji_tags(object) do
  #    tags = object["tag"] || []
  #    emoji = object["emoji"] || []
  #
  #    out =
  #      emoji
  #      |> Enum.map(fn {name, url} ->
  #        %{
  #          "icon" => %{"url" => url, "type" => "Image"},
  #          "name" => ":" <> name <> ":",
  #          "type" => "Emoji",
  #          "updated" => "1970-01-01T00:00:00Z",
  #          "id" => url
  #        }
  #      end)
  #
  #    object
  #    |> Map.put("tag", tags ++ out)
  #  end
  #

  #
  #  def set_sensitive(object) do
  #    tags = object["tag"] || []
  #    Map.put(object, "sensitive", "nsfw" in tags)
  #  end
  #
  def add_attributed_to(object) do
    attributed_to = object["attributedTo"] || object["actor"]

    object |> Map.put("attributedTo", attributed_to)
  end

  #
  #  def prepare_attachments(object) do
  #    attachments =
  #      (object["attachment"] || [])
  #      |> Enum.map(fn data ->
  #        [%{"mediaType" => media_type, "href" => href} | _] = data["url"]
  #        %{"url" => href, "mediaType" => media_type, "name" => data["name"], "type" => "Document"}
  #      end)
  #
  #    object
  #    |> Map.put("attachment", attachments)
  #  end

  @spec fetch_obj_helper(map() | String.t()) :: Event.t() | Comment.t() | Actor.t() | any()
  def fetch_obj_helper(object) do
    Logger.debug("fetch_obj_helper")
    Logger.debug("Fetching object #{inspect(object)}")

    case object |> Utils.get_url() |> ActivityPub.fetch_object_from_url() do
      {:ok, object} ->
        {:ok, object}

      err ->
        Logger.info("Error while fetching #{inspect(object)}")
        {:error, err}
    end
  end

  def fetch_obj_helper_as_activity_streams(object) do
    Logger.debug("fetch_obj_helper_as_activity_streams")

    with {:ok, object} <- fetch_obj_helper(object) do
      {:ok, Convertible.model_to_as(object)}
    end
  end
end
