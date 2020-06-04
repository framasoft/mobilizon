# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/transmogrifier.ex

defmodule Mobilizon.Federation.ActivityPub.Transmogrifier do
  @moduledoc """
  A module to handle coding from internal to wire ActivityPub and back.
  """

  alias Mobilizon.{Actors, Conversations, Events, Resources, Todos}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}

  alias Mobilizon.Web.Email.{Group, Participation}

  require Logger

  def handle_incoming(%{"id" => nil}), do: :error
  def handle_incoming(%{"id" => ""}), do: :error

  def handle_incoming(%{"type" => "Flag"} = data) do
    with params <- Converter.Flag.as_to_model(data) do
      params = %{
        reporter_id: params["reporter"].id,
        reported_id: params["reported"].id,
        comments_ids: params["comments"] |> Enum.map(& &1.id),
        content: params["content"] || "",
        additional: %{
          "cc" => [params["reported"].url]
        },
        event_id: if(is_nil(params["event"]), do: nil, else: params["event"].id || nil),
        local: false
      }

      ActivityPub.flag(params, false)
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

    with object_data <-
           object |> Converter.Comment.as_to_model_data(),
         {:existing_comment, {:error, :comment_not_found}} <-
           {:existing_comment, Conversations.get_comment_from_url_with_preload(object_data.url)},
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

    with object_data <-
           object |> Converter.Event.as_to_model_data(),
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

  def handle_incoming(%{
        "type" => "Create",
        "object" => %{"type" => "TodoList", "id" => object_url} = object,
        "actor" => actor_url
      }) do
    Logger.info("Handle incoming to create a todo list")

    with {:existing_todo_list, nil} <-
           {:existing_todo_list, Todos.get_todo_list_by_url(object_url)},
         {:ok, %Actor{url: actor_url}} <- ActivityPub.get_or_fetch_actor_by_url(actor_url),
         object_data when is_map(object_data) <-
           object |> Converter.TodoList.as_to_model_data(),
         {:ok, %Activity{} = activity, %TodoList{} = todo_list} <-
           ActivityPub.create(:todo_list, object_data, false, %{"actor" => actor_url}) do
      {:ok, activity, todo_list}
    else
      {:error, :group_not_found} -> :error
      {:existing_todo_list, %TodoList{} = todo_list} -> {:ok, nil, todo_list}
    end
  end

  def handle_incoming(%{
        "type" => "Create",
        "object" => %{"type" => "Todo", "id" => object_url} = object
      }) do
    Logger.info("Handle incoming to create a todo")

    with {:existing_todo, nil} <-
           {:existing_todo, Todos.get_todo_by_url(object_url)},
         object_data <-
           object |> Converter.Todo.as_to_model_data(),
         {:ok, %Activity{} = activity, %Todo{} = todo} <-
           ActivityPub.create(:todo, object_data, false) do
      {:ok, activity, todo}
    else
      {:existing_todo, %Todo{} = todo} -> {:ok, nil, todo}
    end
  end

  def handle_incoming(
        %{
          "type" => activity_type,
          "object" => %{"type" => object_type, "id" => object_url} = object,
          "to" => to
        } = data
      )
      when activity_type in ["Create", "Add"] and
             object_type in ["Document", "ResourceCollection"] do
    Logger.info("Handle incoming to create a resource")
    Logger.debug(inspect(data))

    group_url = hd(to)

    with {:existing_resource, nil} <-
           {:existing_resource, Resources.get_resource_by_url(object_url)},
         object_data when is_map(object_data) <-
           object |> Converter.Resource.as_to_model_data(),
         {:member, true} <-
           {:member, Actors.is_member?(object_data.creator_id, object_data.actor_id)},
         {:ok, %Activity{} = activity, %Resource{} = resource} <-
           ActivityPub.create(:resource, object_data, false),
         {:ok, %Actor{type: :Group, id: group_id} = group} <- Actors.get_actor_by_url(group_url),
         announce_id <- "#{object_url}/announces/#{group_id}",
         {:ok, _activity, _resource} <- ActivityPub.announce(group, object, announce_id) do
      {:ok, activity, resource}
    else
      {:existing_resource, %Resource{} = resource} ->
        {:ok, nil, resource}

      {:member, false} ->
        # At some point this should refresh the list of group members
        # if the group is not local before simply returning an error
        :error

      {:error, e} ->
        Logger.error(inspect(e))
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
    with actor_url <- Utils.get_actor(data),
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
    with actor_url <- Utils.get_actor(data),
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

  def handle_incoming(
        %{"type" => "Announce", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    with actor <- Utils.get_actor(data),
         # TODO: Is the following line useful?
         {:ok, %Actor{id: actor_id} = _actor} <- ActivityPub.get_or_fetch_actor_by_url(actor),
         :ok <- Logger.debug("Fetching contained object"),
         {:ok, object} <- fetch_obj_helper_as_activity_streams(object),
         :ok <- Logger.debug("Handling contained object"),
         create_data <- Utils.make_create_data(object),
         :ok <- Logger.debug(inspect(object)),
         {:ok, _activity, entity} <- handle_incoming(create_data),
         :ok <- Logger.debug("Finished processing contained object"),
         {:ok, activity} <- ActivityPub.create_activity(data, false),
         {:ok, %Actor{id: object_owner_actor_id}} <- Actors.get_actor_by_url(object["actor"]),
         {:ok, %Mobilizon.Share{} = _share} <-
           Mobilizon.Share.create(object["id"], actor_id, object_owner_actor_id) do
      {:ok, activity, entity}
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
         object_data <-
           object |> Converter.Actor.as_to_model_data(),
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
          update_data
      ) do
    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url}} <- Actors.get_actor_by_url(actor),
         {:ok, %Event{} = old_event} <-
           object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- Converter.Event.as_to_model_data(object),
         {:origin_check, true} <- {:origin_check, Utils.origin_check?(actor_url, update_data)},
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
    with actor <- Utils.get_actor(data),
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
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{url: actor_url}} <- Actors.get_actor_by_url(actor),
         object_id <- Utils.get_url(object),
         {:origin_check, true} <-
           {:origin_check, Utils.origin_check_from_id?(actor_url, object_id)},
         {:ok, object} <- ActivityPub.fetch_object_from_url(object_id),
         {:ok, activity, object} <- ActivityPub.delete(object, false) do
      {:ok, activity, object}
    else
      {:origin_check, false} ->
        Logger.warn("Object origin check failed")
        :error

      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Join",
          "object" => object,
          "actor" => _actor,
          "id" => id,
          "participationMessage" => note
        } = data
      ) do
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{url: _actor_url} = actor} <- Actors.get_actor_by_url(actor),
         object <- Utils.get_url(object),
         {:ok, object} <- ActivityPub.fetch_object_from_url(object),
         {:ok, activity, object} <-
           ActivityPub.join(object, actor, false, %{url: id, metadata: %{message: note}}) do
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
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{} = actor} <- Actors.get_actor_by_url(actor),
         object <- Utils.get_url(object),
         {:ok, object} <- ActivityPub.fetch_object_from_url(object),
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

  def handle_incoming(
        %{
          "type" => "Invite",
          "object" => object,
          "actor" => _actor,
          "id" => id,
          "target" => target
        } = data
      ) do
    with {:ok, %Actor{} = actor} <- data |> Utils.get_actor() |> Actors.get_actor_by_url(),
         {:ok, object} <- object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         {:ok, %Actor{} = target} <-
           target |> Utils.get_url() |> ActivityPub.get_or_fetch_actor_by_url(),
         {:ok, activity, %Member{} = member} <-
           ActivityPub.invite(object, actor, target, false, %{url: id}),
         :ok <- Group.send_invite_to_user(member) do
      {:ok, activity, member}
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
  #   with actor <- Utils.get_actor(data),
  #        %Actor{} = actor <- ActivityPub.get_or_fetch_actor_by_url(actor),
  #        {:ok, object} <- fetch_obj_helper(object_id) || fetch_obj_helper(object_id),
  #        {:ok, activity, _, _} <- ActivityPub.unlike(actor, object, id, false) do
  #     {:ok, activity}
  #   else
  #     _e -> :error
  #   end
  # end

  def handle_incoming(object) do
    Logger.info("Handing something not supported")
    Logger.debug(inspect(object))
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
    with {:follow, {:ok, %Follower{target_actor: followed} = follow}} <-
           {:follow, get_follow(follow_object)},
         {:same_actor, true} <- {:same_actor, actor.id == followed.id},
         {:ok, activity, _} <-
           ActivityPub.reject(:follow, follow) do
      {:ok, activity, follow}
    else
      {:follow, _err} ->
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
    case get_participant(join_object) do
      {:ok, participant} ->
        do_handle_incoming_accept_join_event(participant, actor_accepting)

      {:error, _err} ->
        case get_member(join_object) do
          {:ok, member} ->
            do_handle_incoming_accept_join_group(member, actor_accepting)

          {:error, _err} ->
            nil
        end
    end
  end

  defp do_handle_incoming_accept_join_event(%Participant{role: :participant}, _actor) do
    Logger.debug(
      "Tried to handle an Accept activity on a Join activity with a event object but the participant is already validated"
    )

    nil
  end

  defp do_handle_incoming_accept_join_event(
         %Participant{role: role, event: event} = participant,
         %Actor{} = actor_accepting
       )
       when role in [:not_approved, :rejected] do
    # TODO: The actor that accepts the Join activity may another one that the event organizer ?
    # Or maybe for groups it's the group that sends the Accept activity
    with {:same_actor, true} <- {:same_actor, actor_accepting.id == event.organizer_actor_id},
         {:ok, %Activity{} = activity, %Participant{role: :participant} = participant} <-
           ActivityPub.accept(
             :join,
             participant,
             false
           ),
         :ok <-
           Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:same_actor} ->
        {:error, "Actor who accepted the join wasn't the event organizer. Quite odd."}

      {:ok, %Participant{role: :participant} = _follow} ->
        {:error, "Participant"}
    end
  end

  defp do_handle_incoming_accept_join_group(%Member{role: :member}, _actor) do
    Logger.debug(
      "Tried to handle an Accept activity on a Join activity with a group object but the member is already validated"
    )

    nil
  end

  defp do_handle_incoming_accept_join_group(
         %Member{role: role, parent: _group} = member,
         %Actor{} = _actor_accepting
       )
       when role in [:not_approved, :rejected, :invited] do
    # TODO: The actor that accepts the Join activity may another one that the event organizer ?
    # Or maybe for groups it's the group that sends the Accept activity
    with {:ok, %Activity{} = activity, %Member{role: :member} = member} <-
           ActivityPub.accept(
             :invite,
             member,
             false
           ) do
      {:ok, activity, member}
    end
  end

  # Handle incoming `Reject` activities wrapping a `Join` activity on an event
  defp do_handle_incoming_reject_join(join_object, %Actor{} = actor_accepting) do
    with {:join_event, {:ok, %Participant{event: event, role: role} = participant}}
         when role != :rejected <-
           {:join_event, get_participant(join_object)},
         # TODO: The actor that accepts the Join activity may another one that the event organizer ?
         # Or maybe for groups it's the group that sends the Accept activity
         {:same_actor, true} <- {:same_actor, actor_accepting.id == event.organizer_actor_id},
         {:ok, activity, participant} <-
           ActivityPub.reject(:join, participant, false),
         :ok <- Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:join_event, {:ok, %Participant{role: :rejected}}} ->
        Logger.warn(
          "Tried to handle an Reject activity on a Join activity with a event object but the participant is already rejected"
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

  @spec get_member(String.t() | map()) :: {:ok, Member.t()} | {:error, String.t()}
  defp get_member(member_object) do
    with member_object_id when not is_nil(member_object_id) <- Utils.get_url(member_object),
         %Member{} = member <-
           Actors.get_member_by_url(member_object_id) do
      {:ok, member}
    else
      {:error, :member_not_found} ->
        {:error, "Member URL not found"}

      _ ->
        {:error, "ActivityPub ID not found in Accept Join object"}
    end
  end

  def prepare_outgoing(%{"type" => _type} = data) do
    data =
      data
      |> Map.merge(Utils.make_json_ld_header())

    {:ok, data}
  end

  @spec fetch_obj_helper(map() | String.t()) :: Event.t() | Comment.t() | Actor.t() | any()
  def fetch_obj_helper(object) do
    Logger.debug("fetch_obj_helper")
    Logger.debug("Fetching object #{inspect(object)}")

    case object |> Utils.get_url() |> ActivityPub.fetch_object_from_url() do
      {:ok, object} ->
        {:ok, object}

      err ->
        Logger.warn("Error while fetching #{inspect(object)}")
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
