defmodule Mobilizon.Service.ActorSuspension do
  @moduledoc """
  Handle actor suspensions
  """

  alias Ecto.Multi
  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Medias.File
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email.Actor, as: ActorEmail
  alias Mobilizon.Web.Email.Group
  alias Mobilizon.Web.Upload
  require Logger
  import Ecto.Query

  @actor_preloads [:user, :organized_events, :comments]
  @delete_actor_default_options [reserve_username: true, suspension: false]

  @doc """
  Deletes an actor.
  """
  @spec suspend_actor(Actor.t(), Keyword.t()) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def suspend_actor(%Actor{} = actor, options \\ @delete_actor_default_options) do
    Logger.info("Going to delete actor #{actor.url}")
    actor = Repo.preload(actor, @actor_preloads)

    delete_actor_options = Keyword.merge(@delete_actor_default_options, options)
    Logger.debug(inspect(delete_actor_options))

    send_suspension_notification(actor)
    notify_event_participants_from_suspension(actor)
    delete_participations(actor)

    multi =
      Multi.new()
      |> maybe_reset_actor_id(actor)
      |> delete_actor_empty_comments(actor)
      |> Multi.run(:remove_banner, fn _, _ -> remove_banner(actor) end)
      |> Multi.run(:remove_avatar, fn _, _ -> remove_avatar(actor) end)

    multi =
      if Keyword.get(delete_actor_options, :reserve_username, true) do
        multi
        |> delete_actor_events(actor)
        |> delete_posts(actor)
        |> delete_ressources(actor)
        |> delete_discussions(actor)
        |> delete_members(actor)
        |> Multi.update(:actor, Actor.delete_changeset(actor))
      else
        Multi.delete(multi, :actor, actor)
      end

    Logger.debug("Going to run the transaction")

    case Repo.transaction(multi) do
      {:ok, %{actor: %Actor{} = actor}} ->
        {:ok, true} = Cachex.del(:activity_pub, "actor_#{actor.preferred_username}")
        Logger.info("Deleted actor #{actor.url}")
        {:ok, actor}

      {:error, remove, error, _} when remove in [:remove_banner, :remove_avatar] ->
        Logger.error("Error while deleting actor's banner or avatar")

        Sentry.capture_message("Error while deleting actor's banner or avatar",
          extra: %{err: error}
        )

        Logger.debug(inspect(error, pretty: true))
        {:error, error}

      err ->
        Logger.error("Unknown error while deleting actor")

        Sentry.capture_message("Error while deleting actor's banner or avatar",
          extra: %{err: err}
        )

        Logger.debug(inspect(err, pretty: true))
        {:error, err}
    end
  end

  # When deleting a profile, reset default_actor_id
  @spec maybe_reset_actor_id(Multi.t(), Actor.t()) :: Multi.t()
  defp maybe_reset_actor_id(%Multi{} = multi, %Actor{type: :Person} = actor) do
    Multi.run(multi, :reset_default_actor_id, fn _, _ ->
      reset_default_actor_id(actor)
    end)
  end

  defp maybe_reset_actor_id(%Multi{} = multi, %Actor{type: :Group} = _actor) do
    multi
  end

  defp delete_actor_empty_comments(%Multi{} = multi, %Actor{id: actor_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Multi.update_all(multi, :empty_comments, where(Comment, [c], c.actor_id == ^actor_id),
      set: [
        text: nil,
        actor_id: nil,
        deleted_at: now
      ]
    )
  end

  @spec notify_event_participants_from_suspension(Actor.t()) :: :ok
  defp notify_event_participants_from_suspension(%Actor{id: actor_id} = actor) do
    actor
    |> get_actor_organizer_events_participations()
    |> preload([:actor, :event])
    |> Repo.all()
    |> Enum.filter(fn %Participant{actor: %Actor{id: participant_actor_id}} ->
      participant_actor_id != actor_id
    end)
    |> Enum.each(&ActorEmail.send_notification_event_participants_from_suspension(&1, actor))
  end

  @spec get_actor_organizer_events_participations(Actor.t()) :: Ecto.Query.t()
  defp get_actor_organizer_events_participations(%Actor{type: :Person, id: actor_id}) do
    do_get_actor_organizer_events_participations()
    |> where([_p, e], e.organizer_actor_id == ^actor_id)
  end

  defp get_actor_organizer_events_participations(%Actor{type: :Group, id: actor_id}) do
    do_get_actor_organizer_events_participations()
    |> where([_p, e], e.attributed_to_id == ^actor_id)
  end

  @spec do_get_actor_organizer_events_participations :: Ecto.Query.t()
  defp do_get_actor_organizer_events_participations do
    Participant
    |> join(:inner, [p], e in Event, on: p.event_id == e.id)
    |> where([_p, e], e.begins_on > ^DateTime.utc_now())
    |> where([p, _e], p.role in [:participant, :moderator, :administrator])
  end

  @spec delete_actor_events(Ecto.Multi.t(), Actor.t()) :: Ecto.Multi.t()
  defp delete_actor_events(%Multi{} = multi, %Actor{type: :Person, id: actor_id}) do
    Multi.delete_all(multi, :delete_events, where(Event, [e], e.organizer_actor_id == ^actor_id))
  end

  defp delete_actor_events(%Multi{} = multi, %Actor{type: :Group, id: actor_id}) do
    Multi.delete_all(multi, :delete_events, where(Event, [e], e.attributed_to_id == ^actor_id))
  end

  defp delete_posts(%Multi{} = multi, %Actor{type: :Person, id: actor_id}) do
    Multi.delete_all(multi, :delete_posts, where(Post, [e], e.author_id == ^actor_id))
  end

  defp delete_posts(%Multi{} = multi, %Actor{type: :Group, id: actor_id}) do
    Multi.delete_all(multi, :delete_posts, where(Post, [e], e.attributed_to_id == ^actor_id))
  end

  defp delete_ressources(%Multi{} = multi, %Actor{type: :Person, id: actor_id}) do
    Multi.delete_all(multi, :delete_resources, where(Resource, [e], e.creator_id == ^actor_id))
  end

  defp delete_ressources(%Multi{} = multi, %Actor{type: :Group, id: actor_id}) do
    Multi.delete_all(multi, :delete_resources, where(Resource, [e], e.actor_id == ^actor_id))
  end

  # Keep discussions just in case, comments are already emptied
  defp delete_discussions(%Multi{} = multi, %Actor{type: :Person}) do
    multi
  end

  defp delete_discussions(%Multi{} = multi, %Actor{type: :Group, id: actor_id}) do
    Multi.delete_all(multi, :delete_discussions, where(Discussion, [e], e.actor_id == ^actor_id))
  end

  @spec delete_participations(Actor.t()) :: :ok
  defp delete_participations(%Actor{type: :Person} = actor) do
    %Actor{participations: participations} = Repo.preload(actor, [:participations])
    Enum.each(participations, &Events.delete_participant/1)
  end

  defp delete_participations(%Actor{type: :Group}), do: :ok

  @spec delete_members(Multi.t(), Actor.t()) :: Multi.t()
  defp delete_members(%Multi{} = multi, %Actor{type: :Person, id: actor_id}) do
    Multi.delete_all(multi, :delete_members, where(Member, [e], e.actor_id == ^actor_id))
  end

  defp delete_members(%Multi{} = multi, %Actor{type: :Group, id: actor_id}) do
    Multi.delete_all(multi, :delete_members, where(Member, [e], e.parent_id == ^actor_id))
  end

  @spec reset_default_actor_id(Actor.t()) :: {:ok, User.t() | nil} | {:error, :user_not_found}
  defp reset_default_actor_id(%Actor{type: :Person, user: %User{id: user_id} = user, id: actor_id}) do
    Logger.debug("reset_default_actor_id")

    new_actor_id =
      user
      |> Users.get_actors_for_user()
      |> Enum.map(& &1.id)
      |> Enum.find(&(&1 !== actor_id))

    {:ok, Users.update_user_default_actor(user_id, new_actor_id)}
  rescue
    _e in Ecto.NoResultsError ->
      {:error, :user_not_found}
  end

  defp reset_default_actor_id(%Actor{type: :Person, user: nil}), do: {:ok, nil}

  @spec remove_banner(Actor.t()) :: {:ok, Actor.t()}
  defp remove_banner(%Actor{banner: nil} = actor), do: {:ok, actor}

  defp remove_banner(%Actor{banner: %File{url: url}} = actor) do
    safe_remove_file(url, actor)
    {:ok, actor}
  end

  @spec remove_avatar(Actor.t()) :: {:ok, Actor.t()}
  defp remove_avatar(%Actor{avatar: avatar} = actor) do
    case avatar do
      %File{url: url} ->
        safe_remove_file(url, actor)
        {:ok, actor}

      nil ->
        {:ok, actor}
    end
  end

  @spec safe_remove_file(String.t(), Actor.t()) :: {:ok, Actor.t()}
  defp safe_remove_file(url, %Actor{} = actor) do
    case Upload.remove(url) do
      {:ok, _value} ->
        {:ok, actor}

      {:error, error} ->
        Logger.error("Error while removing an upload file")
        Logger.debug(inspect(error))

        {:ok, actor}
    end
  end

  @spec send_suspension_notification(Actor.t()) :: :ok
  defp send_suspension_notification(%Actor{type: :Group} = group) do
    group
    |> Actors.list_all_local_members_for_group()
    |> Enum.each(&Group.send_group_suspension_notification/1)
  end

  defp send_suspension_notification(%Actor{} = _actor), do: :ok
end
