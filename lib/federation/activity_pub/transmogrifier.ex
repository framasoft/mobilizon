# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/transmogrifier.ex

defmodule Mobilizon.Federation.ActivityPub.Transmogrifier do
  @moduledoc """
  A module to handle coding from internal to wire ActivityPub and back.
  """

  alias Mobilizon.{Actors, Discussions, Events, Posts, Resources, Todos}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity, Permission, Relay, Utils}
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Types.Ownable
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Service.ErrorReporting.Sentry
  alias Mobilizon.Service.Workers.Background
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Email.Participation
  alias Mobilizon.Web.Endpoint

  require Logger

  @doc """
  Handle incoming activities
  """
  @spec handle_incoming(map()) :: :error | {:error, atom()} | {:ok, any(), struct()}
  def handle_incoming(%{"id" => nil}), do: :error
  def handle_incoming(%{"id" => ""}), do: :error

  def handle_incoming(%{"type" => "Flag"} = data) do
    with params <- Converter.Flag.as_to_model(data) do
      params = %{
        reporter_id: params["reporter"].id,
        reported_id: params["reported"].id,
        comments_ids:
          if(params["comments"], do: params["comments"] |> Enum.map(& &1.id), else: []),
        content: params["content"] || "",
        additional: %{
          "cc" => [params["reported"].url]
        },
        event_id: if(is_nil(params["event"]), do: nil, else: params["event"].id || nil),
        local: false
      }

      Actions.Flag.flag(params, false)
    end
  end

  # Handles a `Create` activity for `Note` (comments) objects
  #
  # The following actions are performed
  #  * Fetch the author of the activity
  #  * Convert the ActivityStream data to the comment model format (it also finds and inserts tags)
  #  * Get (by it's URL) or create the comment with this data
  #  * Insert eventual mentions in the database
  #  * Convert the comment back in ActivityStreams data
  #  * Wrap this data back into a `Create` activity
  #  * Return the activity and the comment object
  def handle_incoming(%{"type" => "Create", "object" => %{"type" => "Note"} = object}) do
    Logger.info("Handle incoming to create notes")

    case Discussions.get_comment_from_url_with_preload(object["id"]) do
      {:error, :comment_not_found} ->
        case Converter.Comment.as_to_model_data(object) do
          %{visibility: visibility, attributed_to_id: attributed_to_id, actor_id: actor_id} =
              object_data
          when visibility === :private and
                 (is_nil(attributed_to_id) or actor_id == attributed_to_id) ->
            Actions.Create.create(:conversation, object_data, false)

          object_data when is_map(object_data) ->
            handle_comment_or_discussion(object_data)

          {:error, err} ->
            {:error, err}
        end

      {:ok, %Comment{} = comment} ->
        # Object already exists
        {:ok, nil, comment}

      {:error, err} ->
        {:error, err}
    end
  end

  # Handles a `Create` activity for `Event` objects
  #
  # The following actions are performed
  #  * Fetch the author of the activity
  #  * Convert the ActivityStream data to the event model format (it also finds and inserts tags)
  #  * Get (by it's URL) or create the event with this data
  #  * Insert eventual mentions in the database
  #  * Convert the event back in ActivityStreams data
  #  * Wrap this data back into a `Create` activity
  #  * Return the activity and the event object
  def handle_incoming(%{"type" => "Create", "object" => %{"type" => "Event"} = object}) do
    Logger.info("Handle incoming to create event")

    with object_data when is_map(object_data) <-
           object |> Converter.Event.as_to_model_data(),
         {:existing_event, nil} <- {:existing_event, Events.get_event_by_url(object_data.url)},
         {:ok, %Activity{} = activity, %Event{} = event} <-
           Actions.Create.create(:event, object_data, false) do
      {:ok, activity, event}
    else
      {:existing_event, %Event{} = event} ->
        {:ok, nil, event}

      err ->
        Logger.debug(inspect(err))
        :error
    end
  end

  def handle_incoming(%{
        "type" => "Create",
        "object" => %{"type" => type, "id" => actor_url} = _object
      })
      when type in ["Group", "Person", "Actor"] do
    Logger.info("Handle incoming to create an actor")

    with {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      {:ok, nil, actor}
    end
  end

  def handle_incoming(%{
        "type" => "Create",
        "object" => %{"type" => "Member"} = object
      }) do
    Logger.info("Handle incoming to create a member")

    with object_data when is_map(object_data) <-
           object |> Converter.Member.as_to_model_data() do
      Logger.debug("Produced the following model data for member")
      Logger.debug(inspect(object_data))

      with {:existing_member, nil} <-
             {:existing_member, Actors.get_member_by_url(object_data.url)},
           %Actor{type: :Group} = group <- Actors.get_actor(object_data.parent_id),
           %Actor{} = actor <- Actors.get_actor(object_data.actor_id),
           {:ok, %Activity{} = activity, %Member{} = member} <-
             Actions.Join.join(group, actor, false, %{
               url: object_data.url,
               metadata: %{role: object_data.role}
             }) do
        {:ok, activity, member}
      else
        {:existing_member, %Member{} = member} ->
          Logger.debug("Member already exists, updating member")
          {:ok, %Member{} = member} = Actors.update_member(member, object_data)

          {:ok, nil, member}
      end
    end
  end

  def handle_incoming(%{
        "type" => "Create",
        "object" =>
          %{"type" => "Article", "actor" => _actor, "attributedTo" => _attributed_to} = object
      }) do
    Logger.info("Handle incoming to create articles")

    with object_data when is_map(object_data) <-
           object |> Converter.Post.as_to_model_data(),
         {:existing_post, nil} <-
           {:existing_post, Posts.get_post_by_url(object_data.url)},
         {:ok, %Activity{} = activity, %Post{} = post} <-
           Actions.Create.create(:post, object_data, false) do
      {:ok, activity, post}
    else
      {:existing_post, %Post{} = post} ->
        {:ok, nil, post}
    end
  end

  # This is a hack to handle Tombstones fetched by AP
  def handle_incoming(%{
        "type" => "Create",
        "object" => %{"type" => "Tombstone", "id" => object_url} = _object
      }) do
    Logger.info("Handle incoming to create a tombstone")

    case ActivityPub.fetch_object_from_url(object_url, force: true) do
      # We already have the tombstone, object is probably already deleted
      {:ok, %Tombstone{} = tombstone} ->
        {:ok, nil, tombstone}

      # Hack because deleted comments
      {:ok, %Comment{deleted_at: deleted_at} = comment} when not is_nil(deleted_at) ->
        {:ok, nil, comment}

      {:ok, entity} ->
        Actions.Delete.delete(entity, Relay.get_actor(), false)

      {:error, err} ->
        Logger.warning("Error while fetching object from URL: #{inspect(err)}")
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Follow", "object" => followed, "actor" => follower, "id" => id} = _data
      ) do
    with {:ok, %Actor{} = followed} <-
           ActivityPubActor.get_or_fetch_actor_by_url(followed, preload: true),
         {:ok, %Actor{} = follower} <- ActivityPubActor.get_or_fetch_actor_by_url(follower),
         {:ok, activity, object} <-
           Actions.Follow.follow(follower, followed, id, false) do
      {:ok, activity, object}
    else
      {:error, :person_no_follow} ->
        Logger.warning("Only group and instances can be followed")
        :error

      {:error, e} ->
        Logger.warning("Unable to handle Follow activity #{inspect(e)}")
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
         {:ok, %Actor{url: actor_url}} <- ActivityPubActor.get_or_fetch_actor_by_url(actor_url),
         object_data when is_map(object_data) <-
           object |> Converter.TodoList.as_to_model_data(),
         {:ok, %Activity{} = activity, %TodoList{} = todo_list} <-
           Actions.Create.create(:todo_list, object_data, false, %{
             "actor" => actor_url
           }) do
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
           Actions.Create.create(:todo, object_data, false) do
      {:ok, activity, todo}
    else
      {:existing_todo, %Todo{} = todo} -> {:ok, nil, todo}
    end
  end

  def handle_incoming(
        %{
          "type" => activity_type,
          "object" => %{"type" => object_type, "id" => object_url} = object
        } = data
      )
      when activity_type in ["Create", "Add"] and
             object_type in ["Document", "ResourceCollection"] do
    Logger.info("Handle incoming to create a resource")
    Logger.debug(inspect(data))

    with {:existing_resource, nil} <-
           {:existing_resource, Resources.get_resource_by_url(object_url)},
         object_data when is_map(object_data) <-
           object |> Converter.Resource.as_to_model_data(),
         {:member, true} <-
           {:member, Actors.member?(object_data.creator_id, object_data.actor_id)},
         {:ok, %Activity{} = activity, %Resource{} = resource} <-
           Actions.Create.create(:resource, object_data, false) do
      {:ok, activity, resource}
    else
      {:existing_resource, %Resource{} = resource} ->
        {:ok, nil, resource}

      {:member, false} ->
        # At some point this should refresh the list of group members
        # if the group is not local before simply returning an error
        :error

      {:error, e} ->
        Logger.debug(inspect(e))
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
         {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(actor_url),
         {:object_not_found, {:ok, %Activity{} = activity, object}} <-
           {:object_not_found,
            do_handle_incoming_accept_following(accepted_object, actor) ||
              do_handle_incoming_accept_join(accepted_object, actor)} do
      {:ok, activity, object}
    else
      {:object_not_found, {:error, "Follow already accepted"}} ->
        Logger.info("Follow was already accepted. Ignoring.")
        :error

      {:object_not_found, nil} ->
        Logger.warning(
          "Unable to process Accept activity #{inspect(id)}. Object #{inspect(accepted_object)} wasn't found."
        )

        :error

      e ->
        Logger.warning(
          "Unable to process Accept activity #{inspect(id)} for object #{inspect(accepted_object)} only returned #{inspect(e)}"
        )

        :error
    end
  end

  def handle_incoming(
        %{"type" => "Reject", "object" => rejected_object, "actor" => _actor, "id" => id} = data
      ) do
    with actor_url <- Utils.get_actor(data),
         {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(actor_url),
         {:object_not_found, {:ok, activity, object}} <-
           {:object_not_found,
            do_handle_incoming_reject_following(rejected_object, actor) ||
              do_handle_incoming_reject_join(rejected_object, actor) ||
              do_handle_incoming_reject_invite(rejected_object, actor)} do
      {:ok, activity, object}
    else
      {:object_not_found, nil} ->
        Logger.warning(
          "Unable to process Reject activity #{inspect(id)}. Object #{inspect(rejected_object)} wasn't found."
        )

        :error

      e ->
        Logger.warning(
          "Unable to process Reject activity #{inspect(id)} for object #{inspect(rejected_object)} only returned #{inspect(e)}"
        )

        :error
    end
  end

  def handle_incoming(
        %{"type" => "Announce", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    with actor_url <- Utils.get_actor(data),
         {:ok, %Actor{id: actor_id, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor_url),
         :ok <- Logger.debug("Fetching contained object"),
         {:ok, entity} <- process_announce_data(object, actor),
         :ok <- eventually_create_share(object, entity, actor_id) do
      {:ok, nil, entity}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Update",
          "object" => %{"type" => object_type} = object,
          "actor" => _actor_id
        } = params
      )
      when object_type in ["Person", "Group", "Application", "Service", "Organization"] do
    with author_url <- Utils.get_actor(params),
         {:ok, %Actor{suspended: false} = author} <-
           ActivityPubActor.get_or_fetch_actor_by_url(author_url),
         {:ok, %Actor{suspended: false} = old_actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(object["id"]),
         object_data <-
           object |> Converter.Actor.as_to_model_data(),
         {:ok, %Activity{} = activity, %Actor{} = new_actor} <-
           Actions.Update.update(old_actor, object_data, false, %{updater_actor: author}) do
      {:ok, activity, new_actor}
    else
      {:error, :update_not_allowed} ->
        Logger.warning(
          "Activity tried to update an actor that's local or not a group: #{inspect(params)}"
        )

        :error

      e ->
        Sentry.capture_message("Error while handling an Update activity",
          extra: %{params: params}
        )

        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => "Event"} = object, "actor" => _actor} =
          update_data
      ) do
    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:ok, %Event{} = old_event} <-
           object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- Converter.Event.as_to_model_data(object),
         {:origin_check, true} <-
           {:origin_check,
            Utils.origin_check?(actor_url, update_data) ||
              Permission.can_update_group_object?(actor, old_event)},
         {:ok, %Activity{} = activity, %Event{} = new_event} <-
           Actions.Update.update(old_event, object_data, false) do
      {:ok, activity, new_event}
    else
      _e ->
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => "Note"} = object, "actor" => _actor} =
          update_data
      ) do
    Logger.info("Handle incoming to update a note")

    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:origin_check, true} <- {:origin_check, Utils.origin_check?(actor_url, update_data)},
         object_data <- Converter.Comment.as_to_model_data(object),
         {:ok, old_entity} <- object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- transform_object_data_for_discussion(object_data),
         {:ok, %Activity{} = activity, new_entity} <-
           Actions.Update.update(old_entity, object_data, false) do
      {:ok, activity, new_entity}
    else
      _e ->
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => "Article"} = object, "actor" => _actor} =
          update_data
      ) do
    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:ok, %Post{} = old_post} <-
           object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- Converter.Post.as_to_model_data(object),
         {:origin_check, true} <-
           {:origin_check,
            Utils.origin_check?(actor_url, update_data["object"]) ||
              Permission.can_update_group_object?(actor, old_post)},
         {:ok, %Activity{} = activity, %Post{} = new_post} <-
           Actions.Update.update(old_post, object_data, false) do
      {:ok, activity, new_post}
    else
      {:origin_check, _} ->
        Logger.warning("Actor tried to update a post but doesn't has the required role")
        :error

      _e ->
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => type} = object, "actor" => _actor} =
          update_data
      )
      when type in ["ResourceCollection", "Document"] do
    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url, suspended: false}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:ok, %Resource{} = old_resource} <-
           object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- Converter.Resource.as_to_model_data(object),
         {:origin_check, true} <-
           {:origin_check,
            Utils.origin_check?(actor_url, update_data) ||
              Permission.can_update_group_object?(actor, old_resource)},
         {:ok, %Activity{} = activity, %Resource{} = new_resource} <-
           Actions.Update.update(old_resource, object_data, false) do
      {:ok, activity, new_resource}
    else
      _e ->
        :error
    end
  end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => "Member"} = object, "actor" => _actor} =
          update_data
      ) do
    Logger.info("Handle incoming to update a member")

    with actor <- Utils.get_actor(update_data),
         {:ok, %Actor{url: actor_url, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:origin_check, true} <- {:origin_check, Utils.origin_check?(actor_url, update_data)},
         object_data <- Converter.Member.as_to_model_data(object),
         {:ok, old_entity} <- object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         {:ok, %Activity{} = activity, new_entity} <-
           Actions.Update.update(old_entity, object_data, false, %{moderator: actor}) do
      {:ok, activity, new_entity}
    else
      _e ->
        :error
    end
  end

  def handle_incoming(%{
        "type" => "Update",
        "object" => %{"type" => "Tombstone"} = object,
        "actor" => _actor
      }) do
    Logger.info("Handle incoming to update a tombstone")

    with object_url <- Utils.get_url(object),
         {:ok, entity} <- ActivityPub.fetch_object_from_url(object_url) do
      Actions.Delete.delete(entity, Relay.get_actor(), false)
    else
      {:ok, %Tombstone{} = tombstone} ->
        {:ok, nil, tombstone}
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
         {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:ok, object} <- fetch_obj_helper_as_activity_streams(object_id),
         {:ok, activity, object} <-
           Actions.Announce.unannounce(
             actor,
             object,
             id,
             cancelled_activity_id,
             false
           ) do
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
    with {:ok, %Actor{domain: nil} = followed} <-
           ActivityPubActor.get_or_fetch_actor_by_url(followed),
         {:ok, %Actor{} = follower} <- ActivityPubActor.get_or_fetch_actor_by_url(follower),
         {:ok, activity, object} <-
           Actions.Follow.unfollow(follower, followed, id, false) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  # We assume everyone on the same instance as the object
  # or who is member of a group has the right to delete the object
  def handle_incoming(
        %{"type" => "Delete", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    Logger.info("Handle incoming to delete an object")

    actor_url = Utils.get_actor(data)
    object_id = Utils.get_url(object)

    case ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      {:error, _err} ->
        {:error, :unknown_actor}

      {:ok, %Actor{} = actor} ->
        # If the actor itself is being deleted, no need to check anything other than the object being remote
        if remote_actor_is_being_deleted(data) do
          Actions.Delete.delete(actor, actor, false)
        else
          handle_group_being_gone(actor, actor_url, object_id)
        end
    end
  end

  def handle_incoming(
        %{"type" => "Move", "object" => %{"type" => type} = object, "actor" => _actor} = data
      )
      when type in ["ResourceCollection", "Document"] do
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{url: actor_url, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         {:ok, %Resource{} = old_resource} <-
           object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         object_data <- Converter.Resource.as_to_model_data(object),
         {:origin_check, true} <-
           {:origin_check,
            Utils.origin_check?(actor_url, data) ||
              Permission.can_update_group_object?(actor, old_resource)},
         {:ok, activity, new_resource} <-
           Actions.Move.move(:resource, old_resource, object_data) do
      {:ok, activity, new_resource}
    else
      e ->
        Logger.debug(inspect(e))

        Sentry.capture_message("Error while handling an Move activity",
          extra: %{data: data}
        )

        :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Join",
          "object" => object,
          "actor" => _actor,
          "id" => id
        } = data
      ) do
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{url: _actor_url, suspended: false} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor),
         object <- Utils.get_url(object),
         {:ok, object} <- ActivityPub.fetch_object_from_url(object),
         {:ok, activity, object} <-
           Actions.Join.join(object, actor, false, %{
             url: id,
             metadata: %{message: Map.get(data, "participationMessage")}
           }) do
      {:ok, activity, object}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  def handle_incoming(%{"type" => "Leave", "object" => object, "actor" => actor} = data) do
    with actor <- Utils.get_actor(data),
         {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(actor),
         object <- Utils.get_url(object),
         {:ok, object} <- ActivityPub.fetch_object_from_url(object),
         {:ok, activity, object} <- Actions.Leave.leave(object, actor, false) do
      {:ok, activity, object}
    else
      {:only_organizer, true} ->
        Logger.warning(
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
    Logger.info("Handle incoming to invite someone")

    with {:ok, %Actor{} = actor} <-
           data |> Utils.get_actor() |> ActivityPubActor.get_or_fetch_actor_by_url(),
         {:ok, object} <- object |> Utils.get_url() |> ActivityPub.fetch_object_from_url(),
         {:ok, %Actor{} = target} <-
           target |> Utils.get_url() |> ActivityPubActor.get_or_fetch_actor_by_url(),
         {:ok, activity, %Member{} = member} <-
           Actions.Invite.invite(object, actor, target, false, %{url: id}) do
      {:ok, activity, member}
    end
  end

  def handle_incoming(
        %{"type" => "Remove", "actor" => actor, "object" => object, "origin" => origin} = data
      ) do
    Logger.info("Handle incoming to remove a member from a group")

    with {:ok, %Actor{} = moderator} <-
           data |> Utils.get_actor() |> ActivityPubActor.get_or_fetch_actor_by_url(),
         {:ok, person_id} <- get_remove_object(object),
         {:ok, %Actor{type: :Group, id: group_id} = group} <-
           origin |> Utils.get_url() |> ActivityPubActor.get_or_fetch_actor_by_url(),
         {:is_admin, true} <-
           {:is_admin, can_remove_actor_from_group?(moderator, group)},
         {:is_member, {:ok, %Member{role: role} = member}} when role != :rejected <-
           {:is_member, Actors.get_member(person_id, group_id)} do
      Actions.Remove.remove(member, group, moderator, false)
    else
      {:is_admin, {:ok, %Member{}}} ->
        Logger.warning(
          "Person #{inspect(actor)} is not an admin from #{inspect(origin)} and can't remove member #{inspect(object)}"
        )

        {:error, "Member already removed"}

      {:is_member, {:ok, %Member{role: :rejected}}} ->
        Logger.warning("Member #{inspect(object)} already removed from #{inspect(origin)}")
        {:error, "Member already removed"}
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
    Logger.info("Handing something with type #{object["type"]} not supported")
    Logger.debug(inspect(object))

    {:error, :not_supported}
  end

  # Handle incoming `Accept` activities wrapping a `Follow` activity
  defp do_handle_incoming_accept_following(follow_object, %Actor{} = actor) do
    with {:follow,
          {:ok, %Follower{approved: false, target_actor: followed, actor: follower} = follow}} <-
           {:follow, get_follow(follow_object)},
         {:same_actor, true} <- {:same_actor, actor.id == followed.id},
         {:ok, %Activity{} = activity, %Follower{approved: true} = follow} <-
           Actions.Accept.accept(
             :follow,
             follow,
             false
           ) do
      relay_actor = Relay.get_actor()

      # If this is an instance follow, refresh the followed profile (especially their outbox)
      if follower.id == relay_actor.id do
        Background.enqueue("refresh_profile", %{
          "actor_id" => followed.id
        })
      end

      {:ok, activity, follow}
    else
      {:follow, {:ok, %Follower{approved: true} = _follow}} ->
        Logger.debug("Follow already accepted")
        {:error, "Follow already accepted"}

      {:follow, _} ->
        Logger.debug(
          "Tried to handle an Accept activity but it's not containing a Follow activity"
        )

        nil

      {:same_actor} ->
        {:error, "Actor who accepted the follow wasn't the target. Quite odd."}
    end
  end

  # Handle incoming `Reject` activities wrapping a `Follow` activity
  defp do_handle_incoming_reject_following(follow_object, %Actor{} = actor) do
    with {:follow, {:ok, %Follower{target_actor: followed} = follow}} <-
           {:follow, get_follow(follow_object)},
         {:same_actor, true} <- {:same_actor, actor.id == followed.id},
         {:ok, activity, _} <-
           Actions.Reject.reject(:follow, follow) do
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
    case get_participant(join_object, actor_accepting) do
      {:ok, activity, participant} ->
        do_handle_incoming_accept_join_event(participant, actor_accepting, activity)

      {:error, _err} ->
        case get_member(join_object) do
          {:ok, %Member{role: :not_approved} = member} ->
            do_handle_incoming_accept_join_group(member, :member, %{moderator: actor_accepting})

          {:ok, %Member{invited_by: nil} = member} ->
            do_handle_incoming_accept_join_group(member, :join)

          {:ok, %Member{} = member} ->
            do_handle_incoming_accept_join_group(member, :invite)

          {:error, _err} ->
            nil
        end
    end
  end

  defp do_handle_incoming_accept_join_event(
         %Participant{role: :participant} = participant,
         _actor,
         activity
       ) do
    Logger.debug(
      "Tried to handle an Accept activity on a Join activity with a event object but the participant is already validated"
    )

    {:ok, activity, participant}
  end

  defp do_handle_incoming_accept_join_event(
         %Participant{role: role, event: event} = participant,
         %Actor{} = actor_accepting,
         _activity
       )
       when role in [:not_approved, :rejected] do
    with %Event{} = event <- Events.get_event_with_preload!(event.id),
         {:can_accept_event_join, true} <-
           {:can_accept_event_join, can_manage_event?(actor_accepting, event)},
         {:ok, %Activity{} = activity, %Participant{role: :participant} = participant} <-
           Actions.Accept.accept(
             :join,
             participant,
             false
           ),
         :ok <-
           Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:can_accept_event_join, false} ->
        {:error, "Actor who accepted the join didn't have permission to do so."}

      {:ok, %Participant{role: :participant} = _follow} ->
        {:error, "Participant"}
    end
  end

  defp do_handle_incoming_accept_join_group(%Member{role: :member}, _type) do
    Logger.debug(
      "Tried to handle an Accept activity on a Join activity with a group object but the member is already validated"
    )

    nil
  end

  defp do_handle_incoming_accept_join_group(
         %Member{role: role, parent: _group} = member,
         type,
         additional \\ %{}
       )
       when role in [:not_approved, :rejected, :invited] and type in [:join, :invite, :member] do
    # Or maybe for groups it's the group that sends the Accept activity
    with {:ok, %Activity{} = activity, %Member{role: :member} = member} <-
           Actions.Accept.accept(
             type,
             member,
             false,
             additional
           ) do
      {:ok, activity, member}
    end
  end

  # Handle incoming `Reject` activities wrapping a `Join` activity on an event
  defp do_handle_incoming_reject_join(join_object, %Actor{} = actor_accepting) do
    with {:join_event, {:ok, _activity, %Participant{event: event, role: role} = participant}}
         when role != :rejected <-
           {:join_event, get_participant(join_object, actor_accepting)},
         {:event, %Event{} = event} <- {:event, Events.get_event_with_preload!(event.id)},
         {:can_accept_event_reject, true} <-
           {:can_accept_event_reject, can_manage_event?(actor_accepting, event)},
         {:ok, activity, participant} <-
           Actions.Reject.reject(:join, participant, false),
         :ok <- Participation.send_emails_to_local_user(participant) do
      {:ok, activity, participant}
    else
      {:join_event, {:ok, _activity, %Participant{role: :rejected}}} ->
        Logger.warning(
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

  defp do_handle_incoming_reject_invite(invite_object, %Actor{} = actor_rejecting) do
    with {:invite, {:ok, %Member{role: :invited, actor_id: actor_id} = member}} <-
           {:invite, get_member(invite_object)},
         {:same_actor, true} <- {:same_actor, actor_rejecting.id == actor_id} do
      Actions.Reject.reject(:invite, member, false)
    end
  end

  # If the object has been announced by a group let's use one of our members to fetch it
  @spec fetch_object_optionally_authenticated(String.t(), Actor.t() | any()) ::
          {:ok, struct()} | {:error, any()}
  defp fetch_object_optionally_authenticated(url, %Actor{type: :Group, id: group_id}) do
    case Actors.get_single_group_member_actor(group_id) do
      %Actor{} = actor ->
        ActivityPub.fetch_object_from_url(url, on_behalf_of: actor, force: true)

      _err ->
        fetch_object_optionally_authenticated(url, nil)
    end
  end

  defp fetch_object_optionally_authenticated(url, _),
    do: ActivityPub.fetch_object_from_url(url, force: true)

  defp eventually_create_share(object, entity, actor_id) do
    with object_id <- object |> Utils.get_url(),
         %Actor{id: object_owner_actor_id} <- Ownable.actor(entity) do
      {:ok, %Mobilizon.Share{} = _share} =
        Mobilizon.Share.create(object_id, actor_id, object_owner_actor_id)
    end

    :ok
  end

  # Comment initiates a whole discussion only if it has full title
  @spec data_for_comment_or_discussion?(map()) :: boolean()
  defp data_for_comment_or_discussion?(object_data) do
    data_a_discussion_initialization?(object_data) and
      is_nil(object_data.discussion_id)
  end

  # Comment initiates a whole discussion only if it has full title
  defp data_a_discussion_initialization?(object_data) do
    not Map.has_key?(object_data, :title) or
      is_nil(object_data.title) or object_data.title == ""
  end

  defp handle_comment_or_discussion(object_data) do
    case Discussions.get_comment_from_url_with_preload(object_data.url) do
      {:error, :comment_not_found} ->
        object_data
        |> transform_object_data_for_discussion()
        |> save_comment_or_discussion()

      {:ok, %Comment{} = comment} ->
        # Object already exists
        {:ok, nil, comment}
    end
  end

  # Comment and conversations have different attributes for actor and groups
  @spec transform_object_data_for_discussion(map()) :: map()
  defp transform_object_data_for_discussion(object_data) do
    # Basic comment
    if data_a_discussion_initialization?(object_data) do
      object_data
    else
      # Conversation
      object_data
      |> Map.put(:creator_id, object_data.actor_id)
      |> Map.put(:actor_id, object_data.attributed_to_id || object_data.actor_id)
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

  defp get_participant(join_object, %Actor{} = actor_accepting, loop \\ 1, activity \\ nil) do
    with join_object_id when not is_nil(join_object_id) <- Utils.get_url(join_object),
         {:not_found, %Participant{} = participant} <-
           {:not_found, Events.get_participant_by_url(join_object_id)} do
      {:ok, activity, participant}
    else
      {:not_found, _err} ->
        with true <- is_map(join_object),
             true <- loop < 2,
             true <- Utils.are_same_origin?(actor_accepting.url, join_object["id"]),
             {:ok, activity, %Participant{url: participant_url}} <- handle_incoming(join_object) do
          get_participant(participant_url, actor_accepting, 2, activity)
        else
          _ ->
            {:error, "Participant URL not found"}
        end

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
        Logger.warning("Error while fetching #{inspect(object)}")
        {:error, err}
    end
  end

  def fetch_obj_helper_as_activity_streams(object) do
    Logger.debug("fetch_obj_helper_as_activity_streams")

    with {:ok, object} <- fetch_obj_helper(object) do
      {:ok, Convertible.model_to_as(object)}
    end
  end

  # Otherwise we need to fetch what's at the URL (this is possible only for objects, not activities)
  defp process_announce_data(%{"id" => url}, %Actor{} = actor),
    do: process_announce_data(url, actor)

  defp process_announce_data(url, %Actor{} = actor) do
    if Utils.are_same_origin?(url, Endpoint.url()) do
      ActivityPub.fetch_object_from_url(url, force: false)
    else
      fetch_object_optionally_authenticated(url, actor)
    end
  end

  defp group_object_gone_check(object_id) do
    Logger.debug("Checking if group object #{object_id} is gone")

    case ActivityPub.fetch_object_from_url(object_id, force: true) do
      # comments are just emptied
      {:ok, %Comment{deleted_at: deleted_at} = object} when not is_nil(deleted_at) ->
        {:ok, object}

      {:error, :http_gone, object} ->
        Logger.debug("object is really gone")
        {:ok, object}

      {:ok, %{url: url} = object} ->
        if Utils.are_same_origin?(url, Endpoint.url()),
          do: {:ok, object},
          else: {:error, "Group object URL remote"}

      {:error, err} ->
        {:error, err}

      err ->
        err
    end
  end

  @spec get_remove_object(map() | String.t()) :: {:ok, integer()}
  defp get_remove_object(object) do
    case object |> Utils.get_url() |> ActivityPub.fetch_object_from_url() do
      {:ok, %Member{actor: %Actor{id: person_id}}} -> {:ok, person_id}
      _ -> {:error, :remove_object_not_found}
    end
  end

  defp can_manage_event?(
         %Actor{url: actor_url} = actor,
         %Event{attributed_to: %Actor{type: :Group, url: group_url} = _group} = event
       ) do
    actor_url == group_url || Permission.can_update_group_object?(actor, event)
  end

  defp can_manage_event?(
         %Actor{id: actor_id},
         %Event{organizer_actor: %Actor{id: organizer_actor_id}}
       ) do
    organizer_actor_id == actor_id
  end

  defp can_manage_event?(%Actor{} = _actor, %Event{} = _event) do
    false
  end

  @spec create_comment_or_discussion(map()) ::
          {:ok, Activity.t(), struct()} | {:error, atom() | Ecto.Changeset.t()}
  defp create_comment_or_discussion(object_data) do
    if data_for_comment_or_discussion?(object_data) do
      Logger.debug("Chosing to create a regular comment")
      Actions.Create.create(:comment, object_data, false)
    else
      Logger.debug("Chosing to initialize or add a comment to a conversation")
      Actions.Create.create(:discussion, object_data, false)
    end
  end

  @spec can_remove_actor_from_group?(Actor.t(), Actor.t()) :: boolean()
  defp can_remove_actor_from_group?(%Actor{} = moderator, %Actor{} = group) do
    case Actors.get_member(moderator.id, group.id) do
      {:ok, %Member{role: role}} when role in [:moderator, :administrator, :creator] ->
        true

      _ ->
        # If member moderator not found, it's probably because no one on this instance is member of this group yet
        # Therefore we can't access the list of admin/moderators and we just trust the origin domain
        moderator.domain == group.domain
    end
  end

  defp remote_actor_is_being_deleted(%{"object" => object} = data) do
    object_id = Utils.get_url(object)
    Utils.get_actor(data) == object_id and not Utils.are_same_origin?(object_id, Endpoint.url())
  end

  @spec save_comment_or_discussion(map()) :: {:ok, Activity.t(), struct()} | :error
  defp save_comment_or_discussion(object_data) do
    case create_comment_or_discussion(object_data) do
      {:ok, %Activity{} = activity, entity} ->
        {:ok, activity, entity}

      {:error, :entity_tombstoned} ->
        Logger.debug("Tried to reply to an event that has been tombstoned")
        :error

      {:error, :event_not_allow_commenting} ->
        Logger.debug("Tried to reply to an event for which comments are closed")
        :error

      {:error, %Ecto.Changeset{} = _changeset} ->
        Logger.debug("Error when saving external comment")
        :error

      {:error, err} ->
        Logger.debug("Generic error when saving external comment: #{inspect(err)}")
        :error
    end
  end

  defp handle_group_being_gone(actor, actor_url, object_id) do
    case group_object_gone_check(object_id) do
      # The group object is no longer there, we can remove the element
      {:ok, entity} ->
        if Utils.origin_check_from_id?(actor_url, object_id) ||
             Permission.can_delete_group_object?(actor, entity) do
          Actions.Delete.delete(entity, actor, false)
        else
          Logger.warning("Object origin check failed")
          :error
        end

      {:error, err} ->
        Logger.debug(inspect(err))
        {:error, err}

      {:error, :http_not_found, err} ->
        Logger.debug(inspect(err))
        {:error, err}
    end
  end
end
