defmodule Mobilizon.Events do
  @moduledoc """
  The Events context.
  """

  import Geo.PostGIS

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  alias Mobilizon.Events.{
    Comment,
    Event,
    FeedToken,
    Participant,
    Session,
    Tag,
    TagRelation,
    Track
  }

  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  defenum(EventVisibility, :event_visibility, [
    :public,
    :unlisted,
    :restricted,
    :private
  ])

  defenum(JoinOptions, :join_options, [
    :free,
    :restricted,
    :invite
  ])

  defenum(EventStatus, :event_status, [
    :tentative,
    :confirmed,
    :cancelled
  ])

  defenum(EventCategory, :event_category, [
    :business,
    :conference,
    :birthday,
    :demonstration,
    :meeting
  ])

  defenum(CommentVisibility, :comment_visibility, [
    :public,
    :unlisted,
    :private,
    :moderated,
    :invite
  ])

  defenum(CommentModeration, :comment_moderation, [
    :allow_all,
    :moderated,
    :closed
  ])

  defenum(ParticipantRole, :participant_role, [
    :not_approved,
    :participant,
    :moderator,
    :administrator,
    :creator
  ])

  @public_visibility [:public, :unlisted]

  @event_preloads [
    :organizer_actor,
    :sessions,
    :tracks,
    :tags,
    :participants,
    :physical_address,
    :picture
  ]

  @comment_preloads [:actor, :attributed_to, :in_reply_to_comment]

  @doc """
  Gets a single event.
  """
  @spec get_event(integer | String.t()) :: {:ok, Event.t()} | {:error, :event_not_found}
  def get_event(id) do
    case Repo.get(Event, id) do
      %Event{} = event ->
        {:ok, event}

      nil ->
        {:error, :event_not_found}
    end
  end

  @doc """
  Gets a single event.
  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  @spec get_event!(integer | String.t()) :: Event.t()
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Gets a single event, with all associations loaded.
  """
  @spec get_event_with_preload(integer | String.t()) ::
          {:ok, Event.t()} | {:error, :event_not_found}
  def get_event_with_preload(id) do
    case Repo.get(Event, id) do
      %Event{} = event ->
        {:ok, Repo.preload(event, @event_preloads)}

      nil ->
        {:error, :event_not_found}
    end
  end

  @doc """
  Gets a single event, with all associations loaded.
  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  @spec get_event_with_preload!(integer | String.t()) :: Event.t()
  def get_event_with_preload!(id) do
    Event
    |> Repo.get!(id)
    |> Repo.preload(@event_preloads)
  end

  @doc """
  Gets an event by its URL.
  """
  @spec get_event_by_url(String.t()) :: Event.t() | nil
  def get_event_by_url(url) do
    url
    |> event_by_url_query()
    |> Repo.one()
  end

  @doc """
  Gets an event by its URL.
  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  @spec get_event_by_url!(String.t()) :: Event.t()
  def get_event_by_url!(url) do
    url
    |> event_by_url_query()
    |> Repo.one!()
  end

  @doc """
  Gets an event by its URL, with all associations loaded.
  """
  @spec get_public_event_by_url_with_preload(String.t()) ::
          {:ok, Event.t()} | {:error, :event_not_found}
  def get_public_event_by_url_with_preload(url) do
    event =
      url
      |> event_by_url_query()
      |> filter_public_visibility()
      |> preload_for_event()
      |> Repo.one()

    case event do
      %Event{} = event ->
        {:ok, event}

      nil ->
        {:error, :event_not_found}
    end
  end

  @doc """
  Gets an event by its URL, with all associations loaded.
  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  @spec get_public_event_by_url_with_preload(String.t()) :: Event.t()
  def get_public_event_by_url_with_preload!(url) do
    url
    |> event_by_url_query()
    |> filter_public_visibility()
    |> preload_for_event()
    |> Repo.one!()
  end

  @doc """
  Gets an event by its UUID, with all associations loaded.
  """
  @spec get_public_event_by_uuid_with_preload(String.t()) :: Event.t() | nil
  def get_public_event_by_uuid_with_preload(uuid) do
    uuid
    |> event_by_uuid_query()
    |> filter_public_visibility()
    |> preload_for_event()
    |> Repo.one()
  end

  @doc """
  Gets an actor's eventual upcoming public event.
  """
  @spec get_upcoming_public_event_for_actor(Actor.t(), String.t() | nil) :: Event.t() | nil
  def get_upcoming_public_event_for_actor(%Actor{id: actor_id}, not_event_uuid \\ nil) do
    actor_id
    |> upcoming_public_event_for_actor_query()
    |> filter_public_visibility()
    |> filter_not_event_uuid(not_event_uuid)
    |> Repo.one()
  end

  @doc """
  Creates an event.
  """
  @spec create_event(map) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event(attrs \\ %{}) do
    with {:ok, %Event{} = event} <- do_create_event(attrs),
         {:ok, %Participant{} = _participant} <-
           %Participant{}
           |> Participant.changeset(%{
             actor_id: event.organizer_actor_id,
             role: :creator,
             event_id: event.id
           })
           |> Repo.insert() do
      {:ok, event}
    end
  end

  @spec do_create_event(map) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  defp do_create_event(attrs) do
    with {:ok, %Event{} = event} <-
           %Event{}
           |> Event.changeset(attrs)
           |> Repo.insert(),
         %Event{} = event <-
           Repo.preload(event, [:tags, :organizer_actor, :physical_address, :picture]),
         {:has_tags, true, _} <- {:has_tags, Map.has_key?(attrs, "tags"), event} do
      event
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, attrs["tags"])
      |> Repo.update()
    else
      {:has_tags, false, event} ->
        {:ok, event}

      error ->
        error
    end
  end

  @doc """
  Updates an event.
  """
  @spec update_event(Event.t(), map) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def update_event(%Event{} = event, attrs) do
    event
    |> Repo.preload(:tags)
    |> Event.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an event.
  """
  @spec delete_event(Event.t()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def delete_event(%Event{} = event), do: Repo.delete(event)

  @doc """
  Deletes an event.
  Raises an exception if it fails.
  """
  @spec delete_event(Event.t()) :: Event.t()
  def delete_event!(%Event{} = event), do: Repo.delete!(event)

  @doc """
  Returns the list of events.
  """
  @spec list_events(integer | nil, integer | nil, atom, atom, boolean, boolean) :: [Event.t()]
  def list_events(
        page \\ nil,
        limit \\ nil,
        sort \\ :begins_on,
        direction \\ :asc,
        is_unlisted \\ false,
        is_future \\ true
      ) do
    query = from(e in Event, preload: [:organizer_actor, :participants])

    query
    |> Page.paginate(page, limit)
    |> sort(sort, direction)
    |> filter_future_events(is_future)
    |> filter_unlisted(is_unlisted)
    |> Repo.all()
  end

  @doc """
  Returns the list of events with the same tags.
  """
  @spec list_events_by_tags([Tag.t()], integer) :: [Event.t()]
  def list_events_by_tags(tags, limit \\ 2) do
    tags
    |> Enum.map(& &1.id)
    |> events_by_tags_query(limit)
    |> Repo.all()
  end

  @doc """
  Lists public events for the actor, with all associations loaded.
  """
  @spec list_public_events_for_actor(Actor.t(), integer | nil, integer | nil) ::
          {:ok, [Event.t()], integer}
  def list_public_events_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    events =
      actor_id
      |> event_for_actor_query()
      |> filter_public_visibility()
      |> preload_for_event()
      |> Page.paginate(page, limit)
      |> Repo.all()

    events_count =
      actor_id
      |> count_events_for_actor_query()
      |> Repo.one()

    {:ok, events, events_count}
  end

  @doc """
  Finds close events to coordinates.
  Radius is in meters and defaults to 50km.
  """
  @spec find_close_events(number, number, number, number) :: [Event.t()]
  def find_close_events(lon, lat, radius \\ 50_000, srid \\ 4326) do
    "SRID=#{srid};POINT(#{lon} #{lat})"
    |> Geo.WKT.decode!()
    |> close_events_query(radius)
    |> Repo.all()
  end

  @doc """
  Counts local events.
  """
  @spec count_local_events :: integer
  def count_local_events do
    count_local_events_query()
    |> filter_public_visibility()
    |> Repo.one()
  end

  @doc """
  Builds a page struct for events by their name.
  """
  @spec build_events_by_name(String.t(), integer | nil, integer | nil) :: Page.t()
  def build_events_by_name(name, page \\ nil, limit \\ nil) do
    name
    |> String.trim()
    |> events_by_name_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Gets a single tag.
  """
  @spec get_tag(integer | String.t()) :: Tag.t() | nil
  def get_tag(id), do: Repo.get(Tag, id)

  @doc """
  Gets a single tag.
  Raises `Ecto.NoResultsError` if the tag does not exist.
  """
  @spec get_tag!(integer | String.t()) :: Tag.t()
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Gets a tag by its slug.
  """
  @spec get_tag_by_slug(String.t()) :: Tag.t() | nil
  def get_tag_by_slug(slug) do
    slug
    |> tag_by_slug_query()
    |> Repo.one()
  end

  @doc """
  Gets an existing tag or creates the new one.
  """
  @spec get_or_create_tag(map) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_tag(%{"name" => "#" <> title}) do
    case Repo.get_by(Tag, title: title) do
      %Tag{} = tag ->
        {:ok, tag}

      nil ->
        create_tag(%{"title" => title})
    end
  end

  @doc """
  Creates a tag.
  """
  @spec create_tag(map) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.
  """
  @spec update_tag(Tag.t(), map) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.
  """
  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def delete_tag(%Tag{} = tag), do: Repo.delete(tag)

  @doc """
  Returns the list of tags.
  """
  @spec list_tags(integer | nil, integer | nil) :: [Tag.t()]
  def list_tags(page \\ nil, limit \\ nil) do
    Tag
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Returns the list of tags for the event.
  """
  @spec list_tags_for_event(integer | String.t(), integer | nil, integer | nil) :: [Tag.t()]
  def list_tags_for_event(event_id, page \\ nil, limit \\ nil) do
    event_id
    |> tags_for_event_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Checks whether two tags are linked or not.
  """
  @spec are_tags_linked(Tag.t(), Tag.t()) :: boolean
  def are_tags_linked(%Tag{id: tag1_id}, %Tag{id: tag2_id}) do
    tag_relation =
      tag1_id
      |> tags_linked_query(tag2_id)
      |> Repo.one()

    !!tag_relation
  end

  @doc """
  Creates a relation between two tags.
  """
  @spec create_tag_relation(map) :: {:ok, TagRelation.t()} | {:error, Ecto.Changeset.t()}
  def create_tag_relation(attrs \\ {}) do
    %TagRelation{}
    |> TagRelation.changeset(attrs)
    |> Repo.insert(
      conflict_target: [:tag_id, :link_id],
      on_conflict: [inc: [weight: 1]]
    )
  end

  @doc """
  Removes a tag relation.
  """
  @spec delete_tag_relation(TagRelation.t()) ::
          {:ok, TagRelation.t()} | {:error, Ecto.Changeset.t()}
  def delete_tag_relation(%TagRelation{} = tag_relation) do
    Repo.delete(tag_relation)
  end

  @doc """
  Returns the tags neighbors for a given tag

  We can't rely on the single many_to_many relation since we also want tags that
  link to our tag, not just tags linked by this one.

  The SQL query looks like this:
  ```sql
  SELECT * FROM tags t
  RIGHT JOIN (
    SELECT weight, link_id AS id
    FROM tag_relations t2
    WHERE tag_id = 1
    UNION ALL
    SELECT tag_id AS id, weight
    FROM tag_relations t2
    WHERE link_id = 1
  ) tr
  ON t.id = tr.id
  ORDER BY tr.weight
  DESC;
  ```
  """
  @spec list_tag_neighbors(Tag.t(), integer, integer) :: [Tag.t()]
  def list_tag_neighbors(%Tag{id: tag_id}, relation_minimum \\ 1, limit \\ 10) do
    tag_id
    |> tag_relation_subquery()
    |> tag_relation_union_subquery(tag_id)
    |> tag_neighbors_query(relation_minimum, limit)
    |> Repo.all()
  end

  @doc """
  Gets a single participant.
  """
  @spec get_participant(integer | String.t(), integer | String.t()) ::
          {:ok, Participant.t()} | {:error, :participant_not_found}
  def get_participant(event_id, actor_id) do
    case Repo.get_by(Participant, event_id: event_id, actor_id: actor_id) do
      %Participant{} = participant ->
        {:ok, participant}

      nil ->
        {:error, :participant_not_found}
    end
  end

  @doc """
  Gets a single participant.
  Raises `Ecto.NoResultsError` if the participant does not exist.
  """
  @spec get_participant!(integer | String.t(), integer | String.t()) :: Participant.t()
  def get_participant!(event_id, actor_id) do
    Repo.get_by!(Participant, event_id: event_id, actor_id: actor_id)
  end

  @doc """
  Gets a participant by its URL.
  """
  @spec get_participant_by_url(String.t()) :: Participant.t() | nil
  def get_participant_by_url(url) do
    url
    |> participant_by_url_query()
    |> Repo.one()
  end

  @doc """
  Gets the default participant role depending on the event join options.
  """
  @spec get_default_participant_role(Event.t()) :: :participant | :not_approved
  def get_default_participant_role(%Event{join_options: :free}), do: :participant
  def get_default_participant_role(%Event{join_options: _}), do: :not_approved

  @doc """
  Creates a participant.
  """
  @spec create_participant(map) :: {:ok, Participant.t()} | {:error, Ecto.Changeset.t()}
  def create_participant(attrs \\ %{}) do
    with {:ok, %Participant{} = participant} <-
           %Participant{}
           |> Participant.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(participant, [:event, :actor])}
    end
  end

  @doc """
  Updates a participant.
  """
  @spec update_participant(Participant.t(), map) ::
          {:ok, Participant.t()} | {:error, Ecto.Changeset.t()}
  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a participant.
  """
  @spec delete_participant(Participant.t()) ::
          {:ok, Participant.t()} | {:error, Ecto.Changeset.t()}
  def delete_participant(%Participant{} = participant), do: Repo.delete(participant)

  @doc """
  Returns the list of participants.
  """
  @spec list_participants :: [Participant.t()]
  def list_participants, do: Repo.all(Participant)

  @doc """
  Returns the list of participants for an event.
  Default behaviour is to not return :not_approved participants
  """
  @spec list_participants_for_event(String.t(), integer | nil, integer | nil, boolean) ::
          [Participant.t()]
  def list_participants_for_event(
        event_uuid,
        page \\ nil,
        limit \\ nil,
        include_not_improved \\ false
      )

  def list_participants_for_event(event_uuid, page, limit, include_not_improved) do
    event_uuid
    |> participants_for_event()
    |> filter_role(include_not_improved)
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Returns the list of organizers participants for an event.
  """
  @spec list_organizers_participants_for_event(
          integer | String.t(),
          integer | nil,
          integer | nil
        ) ::
          [Participant.t()]
  def list_organizers_participants_for_event(event_id, page \\ nil, limit \\ nil) do
    event_id
    |> organizers_participants_for_event()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Returns the list of event participation requests for an actor.
  """
  @spec list_requests_for_actor(Actor.t()) :: [Participant.t()]
  def list_requests_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> requests_for_actor_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of participations for an actor.
  """
  @spec list_event_participations_for_actor(Actor.t(), integer | nil, integer | nil) ::
          [Event.t()]
  def list_event_participations_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> event_participations_for_actor_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Gets a single session.
  Raises `Ecto.NoResultsError` if the session does not exist.
  """
  @spec get_session!(integer | String.t()) :: Session.t()
  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Creates a session.
  """
  @spec create_session(map) :: {:ok, Session.t()} | {:error, Ecto.Changeset.t()}
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a session.
  """
  @spec update_session(Session.t(), map) :: {:ok, Session.t()} | {:error, Ecto.Changeset.t()}
  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a session.
  """
  @spec delete_session(Session.t()) :: {:ok, Session.t()} | {:error, Ecto.Changeset.t()}
  def delete_session(%Session{} = session), do: Repo.delete(session)

  @doc """
  Returns the list of sessions.
  """
  @spec list_sessions :: [Session.t()]
  def list_sessions, do: Repo.all(Session)

  @doc """
  Returns the list of sessions for the event.
  """
  @spec list_sessions_for_event(Event.t()) :: [Session.t()]
  def list_sessions_for_event(%Event{id: event_id}) do
    event_id
    |> sessions_for_event_query()
    |> Repo.all()
  end

  @doc """
  Gets a single track.
  Raises `Ecto.NoResultsError` if the track does not exist.
  """
  @spec get_track!(integer | String.t()) :: Track.t()
  def get_track!(id), do: Repo.get!(Track, id)

  @doc """
  Creates a track.
  """
  @spec create_track(map) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a track.
  """
  @spec update_track(Track.t(), map) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a track.
  """
  @spec delete_track(Track.t()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def delete_track(%Track{} = track), do: Repo.delete(track)

  @doc """
  Returns the list of tracks.
  """
  @spec list_tracks :: [Track.t()]
  def list_tracks, do: Repo.all(Track)

  @doc """
  Returns the list of sessions for the track.
  """
  @spec list_sessions_for_track(Track.t()) :: [Session.t()]
  def list_sessions_for_track(%Track{id: track_id}) do
    track_id
    |> sessions_for_track_query()
    |> Repo.all()
  end

  @doc """
  Gets a single comment.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment!(integer | String.t()) :: Comment.t()
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Gets a comment by its URL.
  """
  @spec get_comment_from_url(String.t()) :: Comment.t() | nil
  def get_comment_from_url(url), do: Repo.get_by(Comment, url: url)

  @doc """
  Gets a comment by its URL.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment_from_url!(String.t()) :: Comment.t()
  def get_comment_from_url!(url), do: Repo.get_by!(Comment, url: url)

  @doc """
  Gets a comment by its URL, with all associations loaded.
  """
  @spec get_comment_from_url_with_preload(String.t()) ::
          {:ok, Comment.t()} | {:error, :comment_not_found}
  def get_comment_from_url_with_preload(url) do
    query = from(c in Comment, where: c.url == ^url)

    comment =
      query
      |> preload_for_comment()
      |> Repo.one()

    case comment do
      %Comment{} = comment ->
        {:ok, comment}

      nil ->
        {:error, :comment_not_found}
    end
  end

  @doc """
  Gets a comment by its URL, with all associations loaded.
  Raises `Ecto.NoResultsError` if the comment does not exist.
  """
  @spec get_comment_from_url_with_preload(String.t()) :: Comment.t()
  def get_comment_from_url_with_preload!(url) do
    Comment
    |> Repo.get_by!(url: url)
    |> Repo.preload(@comment_preloads)
  end

  @doc """
  Gets a comment by its UUID, with all associations loaded.
  """
  @spec get_comment_from_uuid_with_preload(String.t()) :: Comment.t()
  def get_comment_from_uuid_with_preload(uuid) do
    Comment
    |> Repo.get_by(uuid: uuid)
    |> Repo.preload(@comment_preloads)
  end

  @doc """
  Creates a comment.
  """
  @spec create_comment(map) :: {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create_comment(attrs \\ %{}) do
    with {:ok, %Comment{} = comment} <-
           %Comment{}
           |> Comment.changeset(attrs)
           |> Repo.insert(),
         %Comment{} = comment <- Repo.preload(comment, @comment_preloads) do
      {:ok, comment}
    end
  end

  @doc """
  Updates a comment.
  """
  @spec update_comment(Comment.t(), map) :: {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.
  """
  @spec delete_comment(Comment.t()) :: {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def delete_comment(%Comment{} = comment), do: Repo.delete(comment)

  @doc """
  Returns the list of public comments.
  """
  @spec list_comments :: [Comment.t()]
  def list_comments do
    Repo.all(from(c in Comment, where: c.visibility == ^:public))
  end

  @doc """
  Returns the list of public comments for the actor.
  """
  @spec list_public_events_for_actor(Actor.t(), integer | nil, integer | nil) ::
          {:ok, [Comment.t()], integer}
  def list_public_comments_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    comments =
      actor_id
      |> public_comments_for_actor_query()
      |> Page.paginate(page, limit)
      |> Repo.all()

    count_comments =
      actor_id
      |> count_comments_query()
      |> Repo.one()

    {:ok, comments, count_comments}
  end

  @doc """
  Returns the list of comments by an actor and a list of ids.
  """
  @spec list_comments_by_actor_and_ids(integer | String.t(), [integer | String.t()]) ::
          [Comment.t()]
  def list_comments_by_actor_and_ids(actor_id, comment_ids \\ [])
  def list_comments_by_actor_and_ids(_actor_id, []), do: []

  def list_comments_by_actor_and_ids(actor_id, comment_ids) do
    Comment
    |> where([c], c.id in ^comment_ids)
    |> where([c], c.actor_id == ^actor_id)
    |> Repo.all()
  end

  @doc """
  Counts local comments.
  """
  @spec count_local_comments :: integer
  def count_local_comments, do: Repo.one(count_local_comments_query())

  @doc """
  Gets a single feed token.
  """
  @spec get_feed_token(String.t()) :: FeedToken.t() | nil
  def get_feed_token(token) do
    token
    |> feed_token_query()
    |> Repo.one()
  end

  @doc """
  Gets a single feed token.
  Raises `Ecto.NoResultsError` if the feed token does not exist.
  """
  @spec get_feed_token!(String.t()) :: FeedToken.t()
  def get_feed_token!(token) do
    token
    |> feed_token_query()
    |> Repo.one!()
  end

  @doc """
  Creates a feed token.
  """
  @spec create_feed_token(map) :: {:ok, FeedToken.t()} | {:error, Ecto.Changeset.t()}
  def create_feed_token(attrs \\ %{}) do
    attrs = Map.put(attrs, "token", Ecto.UUID.generate())

    %FeedToken{}
    |> FeedToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feed token.
  """
  @spec update_feed_token(FeedToken.t(), map) ::
          {:ok, FeedToken.t()} | {:error, Ecto.Changeset.t()}
  def update_feed_token(%FeedToken{} = feed_token, attrs) do
    feed_token
    |> FeedToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feed token.
  """
  @spec delete_feed_token(FeedToken.t()) :: {:ok, FeedToken.t()} | {:error, Ecto.Changeset.t()}
  def delete_feed_token(%FeedToken{} = feed_token), do: Repo.delete(feed_token)

  @doc """
  Returns the list of feed tokens for an user.
  """
  @spec list_feed_tokens_for_user(User.t()) :: [FeedTokens.t()]
  def list_feed_tokens_for_user(%User{id: user_id}) do
    user_id
    |> feed_token_for_user_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of feed tokens for an actor.
  """
  @spec list_feed_tokens_for_actor(Actor.t()) :: [FeedTokens.t()]
  def list_feed_tokens_for_actor(%Actor{id: actor_id, domain: nil}) do
    actor_id
    |> feed_token_for_actor_query()
    |> Repo.all()
  end

  @spec event_by_url_query(String.t()) :: Ecto.Query.t()
  defp event_by_url_query(url) do
    from(e in Event, where: e.url == ^url)
  end

  @spec event_by_uuid_query(String.t()) :: Ecto.Query.t()
  defp event_by_uuid_query(uuid) do
    from(e in Event, where: e.uuid == ^uuid)
  end

  @spec event_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp event_for_actor_query(actor_id) do
    from(
      e in Event,
      where: e.organizer_actor_id == ^actor_id,
      order_by: [desc: :id]
    )
  end

  @spec upcoming_public_event_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp upcoming_public_event_for_actor_query(actor_id) do
    from(
      e in Event,
      where:
        e.organizer_actor_id == ^actor_id and
          e.begins_on > ^DateTime.utc_now(),
      order_by: [asc: :begins_on],
      limit: 1,
      preload: [
        :organizer_actor,
        :tags,
        :participants,
        :physical_address
      ]
    )
  end

  @spec close_events_query(Geo.geometry(), number) :: Ecto.Query.t()
  defp close_events_query(point, radius) do
    from(
      e in Event,
      join: a in Address,
      on: a.id == e.physical_address_id,
      where: e.visibility == ^:public and st_dwithin_in_meters(^point, a.geom, ^radius),
      preload: :organizer_actor
    )
  end

  @spec events_by_name_query(String.t()) :: Ecto.Query.t()
  defp events_by_name_query(name) do
    from(
      e in Event,
      where:
        e.visibility == ^:public and
          fragment("f_unaccent(?) %> f_unaccent(?)", e.title, ^name),
      order_by: fragment("word_similarity(?, ?) desc", e.title, ^name),
      preload: [:organizer_actor]
    )
  end

  @spec events_by_tags_query([integer], integer) :: Ecto.Query.t()
  def events_by_tags_query(tags_ids, limit) do
    from(
      e in Event,
      distinct: e.uuid,
      join: te in "events_tags",
      on: e.id == te.event_id,
      where: e.begins_on > ^DateTime.utc_now(),
      where: e.visibility in ^@public_visibility,
      where: te.tag_id in ^tags_ids,
      order_by: [asc: e.begins_on],
      limit: ^limit
    )
  end

  @spec count_events_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp count_events_for_actor_query(actor_id) do
    from(
      e in Event,
      select: count(e.id),
      where: e.organizer_actor_id == ^actor_id
    )
  end

  @spec count_local_events_query :: Ecto.Query.t()
  defp count_local_events_query do
    from(e in Event, select: count(e.id), where: e.local == ^true)
  end

  @spec tag_by_slug_query(String.t()) :: Ecto.Query.t()
  defp tag_by_slug_query(slug) do
    from(t in Tag, where: t.slug == ^slug)
  end

  @spec tags_for_event_query(integer) :: Ecto.Query.t()
  defp tags_for_event_query(event_id) do
    from(
      t in Tag,
      join: e in "events_tags",
      on: t.id == e.tag_id,
      where: e.event_id == ^event_id
    )
  end

  @spec tags_linked_query(integer, integer) :: Ecto.Query.t()
  defp tags_linked_query(tag1_id, tag2_id) do
    from(
      tr in TagRelation,
      where:
        tr.tag_id == ^min(tag1_id, tag2_id) and
          tr.link_id == ^max(tag1_id, tag2_id)
    )
  end

  @spec tag_relation_subquery(integer) :: Ecto.Query.t()
  defp tag_relation_subquery(tag_id) do
    from(
      tr in TagRelation,
      select: %{id: tr.tag_id, weight: tr.weight},
      where: tr.link_id == ^tag_id
    )
  end

  @spec tag_relation_union_subquery(Ecto.Query.t(), integer) :: Ecto.Query.t()
  defp tag_relation_union_subquery(subquery, tag_id) do
    from(
      tr in TagRelation,
      select: %{id: tr.link_id, weight: tr.weight},
      union_all: ^subquery,
      where: tr.tag_id == ^tag_id
    )
  end

  @spec tag_neighbors_query(Ecto.Query.t(), integer, integer) :: Ecto.Query.t()
  defp tag_neighbors_query(subquery, relation_minimum, limit) do
    from(
      t in Tag,
      right_join: q in subquery(subquery),
      on: [id: t.id],
      where: q.weight >= ^relation_minimum,
      limit: ^limit,
      order_by: [desc: q.weight]
    )
  end

  @spec participant_by_url_query(String.t()) :: Ecto.Query.t()
  defp participant_by_url_query(url) do
    from(
      p in Participant,
      where: p.url == ^url,
      preload: [:actor, :event]
    )
  end

  @spec participants_for_event(String.t()) :: Ecto.Query.t()
  defp participants_for_event(event_uuid) do
    from(
      p in Participant,
      join: e in Event,
      on: p.event_id == e.id,
      where: e.uuid == ^event_uuid,
      preload: [:actor]
    )
  end

  defp organizers_participants_for_event(event_id) do
    from(
      p in Participant,
      where: p.event_id == ^event_id and p.role == ^:creator,
      preload: [:actor]
    )
  end

  @spec requests_for_actor_query(integer) :: Ecto.Query.t()
  defp requests_for_actor_query(actor_id) do
    from(p in Participant, where: p.actor_id == ^actor_id and p.role == ^:not_approved)
  end

  @spec event_participations_for_actor_query(integer) :: Ecto.Query.t()
  def event_participations_for_actor_query(actor_id) do
    from(
      e in Event,
      join: p in Participant,
      join: a in Actor,
      on: p.actor_id == a.id,
      on: p.event_id == e.id,
      where: a.id == ^actor_id and p.role != ^:not_approved,
      preload: [:picture, :tags]
    )
  end

  @spec sessions_for_event_query(integer) :: Ecto.Query.t()
  defp sessions_for_event_query(event_id) do
    from(
      s in Session,
      join: e in Event,
      on: s.event_id == e.id,
      where: e.id == ^event_id
    )
  end

  @spec sessions_for_track_query(integer) :: Ecto.Query.t()
  defp sessions_for_track_query(track_id) do
    from(s in Session, where: s.track_id == ^track_id)
  end

  defp public_comments_for_actor_query(actor_id) do
    from(
      c in Comment,
      where: c.actor_id == ^actor_id and c.visibility in ^@public_visibility,
      order_by: [desc: :id],
      preload: [
        :actor,
        :in_reply_to_comment,
        :origin_comment,
        :event
      ]
    )
  end

  @spec count_comments_query(integer) :: Ecto.Query.t()
  defp count_comments_query(actor_id) do
    from(c in Comment, select: count(c.id), where: c.actor_id == ^actor_id)
  end

  @spec count_local_comments_query :: Ecto.Query.t()
  defp count_local_comments_query do
    from(
      c in Comment,
      select: count(c.id),
      where: c.local == ^true and c.visibility in ^@public_visibility
    )
  end

  @spec feed_token_query(String.t()) :: Ecto.Query.t()
  defp feed_token_query(token) do
    from(ftk in FeedToken, where: ftk.token == ^token, preload: [:actor, :user])
  end

  @spec feed_token_for_user_query(integer) :: Ecto.Query.t()
  defp feed_token_for_user_query(user_id) do
    from(tk in FeedToken, where: tk.user_id == ^user_id, preload: [:actor, :user])
  end

  @spec feed_token_for_actor_query(integer) :: Ecto.Query.t()
  defp feed_token_for_actor_query(actor_id) do
    from(tk in FeedToken, where: tk.actor_id == ^actor_id, preload: [:actor, :user])
  end

  @spec filter_public_visibility(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_public_visibility(query) do
    from(e in query, where: e.visibility in ^@public_visibility)
  end

  @spec filter_not_event_uuid(Ecto.Query.t(), String.t() | nil) :: Ecto.Query.t()
  defp filter_not_event_uuid(query, nil), do: query

  defp filter_not_event_uuid(query, not_event_uuid) do
    from(e in query, where: e.uuid != ^not_event_uuid)
  end

  @spec filter_future_events(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp filter_future_events(query, true) do
    from(q in query, where: q.begins_on > ^DateTime.utc_now())
  end

  defp filter_future_events(query, false), do: query

  @spec filter_unlisted(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp filter_unlisted(query, true) do
    from(q in query, where: q.visibility in ^@public_visibility)
  end

  defp filter_unlisted(query, false) do
    from(q in query, where: q.visibility == ^:public)
  end

  @spec filter_role(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp filter_role(query, false) do
    from(p in query, where: p.role != ^:not_approved)
  end

  defp filter_role(query, true), do: query

  @spec preload_for_event(Ecto.Query.t()) :: Ecto.Query.t()
  defp preload_for_event(query), do: preload(query, ^@event_preloads)

  @spec preload_for_comment(Ecto.Query.t()) :: Ecto.Query.t()
  defp preload_for_comment(query), do: preload(query, ^@comment_preloads)
end
