defmodule Mobilizon.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  import Mobilizon.Ecto

  alias Mobilizon.Repo
  alias Mobilizon.Events.{Event, Comment, Participant}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  def data() do
    Dataloader.Ecto.new(Mobilizon.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end

  def get_public_events_for_actor(%Actor{id: actor_id} = _actor, page \\ nil, limit \\ nil) do
    query =
      from(
        e in Event,
        where: e.organizer_actor_id == ^actor_id and e.visibility in [^:public, ^:unlisted],
        order_by: [desc: :id],
        preload: [
          :organizer_actor,
          :sessions,
          :tracks,
          :tags,
          :participants,
          :physical_address
        ]
      )
      |> paginate(page, limit)

    events = Repo.all(query)

    count_events =
      Repo.one(from(e in Event, select: count(e.id), where: e.organizer_actor_id == ^actor_id))

    {:ok, events, count_events}
  end

  def count_local_events do
    Repo.one(
      from(
        e in Event,
        select: count(e.id),
        where: e.local == ^true and e.visibility in [^:public, ^:unlisted]
      )
    )
  end

  def count_local_comments do
    Repo.one(
      from(
        c in Comment,
        select: count(c.id),
        where: c.local == ^true and c.visibility in [^:public, ^:unlisted]
      )
    )
  end

  import Geo.PostGIS

  @doc """
  Find close events to coordinates

  Radius is in meters and defaults to 50km.
  """
  @spec find_close_events(number(), number(), number(), number()) :: list(Event.t())
  def find_close_events(lon, lat, radius \\ 50_000, srid \\ 4326) do
    with {:ok, point} <- Geo.WKT.decode("SRID=#{srid};POINT(#{lon} #{lat})") do
      Repo.all(
        from(
          e in Event,
          join: a in Address,
          on: a.id == e.physical_address_id,
          where: e.visibility == ^:public and st_dwithin_in_meters(^point, a.geom, ^radius),
          preload: :organizer_actor
        )
      )
    end
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Gets a single event.
  """
  def get_event(id) do
    case Repo.get(Event, id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  @doc """
  Gets an event by it's URL
  """
  def get_event_by_url(url) do
    Repo.get_by(Event, url: url)
  end

  @doc """
  Gets an event by it's URL
  """
  def get_event_by_url!(url) do
    Repo.get_by!(Event, url: url)
  end

  # @doc """
  # Gets an event by it's UUID
  # """
  # @depreciated "Use get_event_full_by_uuid/3 instead"
  # def get_event_by_uuid(uuid) do
  #   Repo.get_by(Event, uuid: uuid)
  # end

  @doc """
  Gets a full event by it's UUID
  """
  @spec get_event_full_by_uuid(String.t()) :: Event.t()
  def get_event_full_by_uuid(uuid) do
    from(
      e in Event,
      where: e.uuid == ^uuid and e.visibility in [^:public, ^:unlisted],
      preload: [
        :organizer_actor,
        :sessions,
        :tracks,
        :tags,
        :participants,
        :physical_address
      ]
    )
    |> Repo.one()
  end

  def get_cached_event_full_by_uuid(uuid) do
    Cachex.fetch(:activity_pub, "event_" <> uuid, fn "event_" <> uuid ->
      with %Event{} = event <- get_event_full_by_uuid(uuid) do
        {:commit, event}
      else
        _ -> {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a single event, with all associations loaded.
  """
  def get_event_full!(id) do
    event = Repo.get!(Event, id)

    Repo.preload(event, [
      :organizer_actor,
      :sessions,
      :tracks,
      :tags,
      :participants,
      :physical_address
    ])
  end

  @doc """
  Gets an event by it's URL
  """
  def get_event_full_by_url(url) do
    case Repo.one(
           from(e in Event,
             where: e.url == ^url and e.visibility in [^:public, ^:unlisted],
             preload: [
               :organizer_actor,
               :sessions,
               :tracks,
               :tags,
               :participants,
               :physical_address
             ]
           )
         ) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  @doc """
  Gets an event by it's URL
  """
  def get_event_full_by_url!(url) do
    Repo.one(
      from(e in Event,
        where: e.url == ^url and e.visibility in [^:public, ^:unlisted],
        preload: [
          :organizer_actor,
          :sessions,
          :tracks,
          :tags,
          :participants,
          :physical_address
        ]
      )
    )
  end

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events(page \\ nil, limit \\ nil) do
    query =
      from(
        e in Event,
        where: e.visibility == ^:public,
        preload: [:organizer_actor, :participants]
      )
      |> paginate(page, limit)

    Repo.all(query)
  end

  @doc """
  Find events by name
  """
  def find_events_by_name(name, page \\ nil, limit \\ nil)
  def find_events_by_name("", page, limit), do: list_events(page, limit)

  def find_events_by_name(name, page, limit) do
    name = String.trim(name)

    query =
      from(e in Event,
        where:
          e.visibility == ^:public and
            fragment(
              "f_unaccent(?) %> f_unaccent(?)",
              e.title,
              ^name
            ),
        order_by:
          fragment(
            "word_similarity(?, ?) desc",
            e.title,
            ^name
          ),
        preload: [:organizer_actor]
      )
      |> paginate(page, limit)

    Repo.all(query)
  end

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    with {:ok, %Event{} = event} <- %Event{} |> Event.changeset(attrs) |> Repo.insert(),
         {:ok, %Participant{} = _participant} <-
           %Participant{}
           |> Participant.changeset(%{
             actor_id: event.organizer_actor_id,
             role: :creator,
             event_id: event.id
           })
           |> Repo.insert() do
      {:ok, Repo.preload(event, [:organizer_actor])}
    end
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Deletes a Event.

  Raises an exception if it fails.
  """
  def delete_event!(%Event{} = event) do
    Repo.delete!(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{source: %Event{}}

  """
  def change_event(%Event{} = event) do
    Event.changeset(event, %{})
  end

  alias Mobilizon.Events.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags(page \\ nil, limit \\ nil) do
    Repo.all(
      Tag
      |> paginate(page, limit)
    )
  end

  @doc """
  Returns the list of tags for an event.

  ## Examples

      iex> list_tags_for_event(id)
      [%Participant{}, ...]

  """
  def list_tags_for_event(id, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        t in Tag,
        join: e in "events_tags",
        on: t.id == e.tag_id,
        where: e.event_id == ^id
      )
      |> paginate(page, limit)
    )
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{source: %Tag{}}

  """
  def change_tag(%Tag{} = tag) do
    Tag.changeset(tag, %{})
  end

  alias Mobilizon.Events.TagRelation

  @doc """
  Create a relation between two tags
  """
  @spec create_tag_relation(map()) :: {:ok, TagRelation.t()} | {:error, Ecto.Changeset.t()}
  def create_tag_relation(attrs \\ {}) do
    %TagRelation{}
    |> TagRelation.changeset(attrs)
    |> Repo.insert(conflict_target: [:tag_id, :link_id], on_conflict: [inc: [weight: 1]])
  end

  @doc """
  Remove a tag relation
  """
  def delete_tag_relation(%TagRelation{} = tag_relation) do
    Repo.delete(tag_relation)
  end

  @doc """
  Returns whether two tags are linked or not
  """
  def are_tags_linked(%Tag{id: tag1_id}, %Tag{id: tag2_id}) do
    case from(tr in TagRelation,
           where: tr.tag_id == ^min(tag1_id, tag2_id) and tr.link_id == ^max(tag1_id, tag2_id)
         )
         |> Repo.one() do
      %TagRelation{} -> true
      _ -> false
    end
  end

  @doc """
  Returns the tags neighbors for a given tag

  We can't rely on the single many_to_many relation since we also want tags that link to our tag, not just tags linked by this one

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
  def tag_neighbors(%Tag{id: id}, relation_minimum \\ 1, limit \\ 10) do
    query2 =
      from(tr in TagRelation,
        select: %{id: tr.tag_id, weight: tr.weight},
        where: tr.link_id == ^id
      )

    query =
      from(tr in TagRelation,
        select: %{id: tr.link_id, weight: tr.weight},
        union_all: ^query2,
        where: tr.tag_id == ^id
      )

    final_query =
      from(t in Tag,
        right_join: q in subquery(query),
        on: [id: t.id],
        where: q.weight >= ^relation_minimum,
        limit: ^limit,
        order_by: [desc: q.weight]
      )

    Repo.all(final_query)
  end

  alias Mobilizon.Events.Participant

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants do
    Repo.all(Participant)
  end

  @doc """
  Returns the list of participants for an event.

  Default behaviour is to not return :not_approved participants

  ## Examples

      iex> list_participants_for_event(someuuid)
      [%Participant{}, ...]

  """
  def list_participants_for_event(uuid, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        p in Participant,
        join: e in Event,
        on: p.event_id == e.id,
        where: e.uuid == ^uuid and p.role != ^:not_approved,
        preload: [:actor]
      )
      |> paginate(page, limit)
    )
  end

  @doc """
  Returns the list of organizers participants for an event.

  ## Examples

      iex> list_organizers_participants_for_event(id)
      [%Participant{role: :creator}, ...]

  """
  def list_organizers_participants_for_event(id, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        p in Participant,
        where: p.event_id == ^id and p.role == ^:creator,
        preload: [:actor]
      )
      |> paginate(page, limit)
    )
  end

  @doc """
  Gets a single participant.

  Raises `Ecto.NoResultsError` if the Participant does not exist.

  ## Examples

      iex> get_participant!(123)
      %Participant{}

      iex> get_participant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_participant!(event_id, actor_id) do
    Repo.get_by!(Participant, event_id: event_id, actor_id: actor_id)
  end

  @doc """
  Get a single participant
  """
  def get_participant(event_id, actor_id) do
    case Repo.get_by(Participant, event_id: event_id, actor_id: actor_id) do
      nil -> {:error, :participant_not_found}
      participant -> {:ok, participant}
    end
  end

  @doc """
  Creates a participant.

  ## Examples

      iex> create_participant(%{field: value})
      {:ok, %Participant{}}

      iex> create_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a participant.

  ## Examples

      iex> update_participant(participant, %{field: new_value})
      {:ok, %Participant{}}

      iex> update_participant(participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Participant.

  ## Examples

      iex> delete_participant(participant)
      {:ok, %Participant{}}

      iex> delete_participant(participant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_participant(%Participant{} = participant) do
    Repo.delete(participant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking participant changes.

  ## Examples

      iex> change_participant(participant)
      %Ecto.Changeset{source: %Participant{}}

  """
  def change_participant(%Participant{} = participant) do
    Participant.changeset(participant, %{})
  end

  @doc """
  Get the default participant role depending on the event join options
  """
  def get_default_participant_role(%Event{} = event) do
    case event.join_options do
      # Participant
      :free -> :participant
      # Not approved
      _ -> :not_approved
    end
  end

  @doc """
  List event participation requests for an actor
  """
  @spec list_requests_for_actor(Actor.t()) :: list(Participant.t())
  def list_requests_for_actor(%Actor{id: actor_id}) do
    Repo.all(from(p in Participant, where: p.actor_id == ^actor_id and p.role == ^:not_approved))
  end

  alias Mobilizon.Events.Session

  @doc """
  Returns the list of sessions.

  ## Examples

      iex> list_sessions()
      [%Session{}, ...]

  """
  def list_sessions do
    Repo.all(Session)
  end

  @doc """
  Returns the list of sessions for an event
  """
  @spec list_sessions_for_event(Event.t()) :: list(Session.t())
  def list_sessions_for_event(%Event{id: event_id}) do
    Repo.all(
      from(
        s in Session,
        join: e in Event,
        on: s.event_id == e.id,
        where: e.id == ^event_id
      )
    )
  end

  @doc """
  Gets a single session.

  Raises `Ecto.NoResultsError` if the Session does not exist.

  ## Examples

      iex> get_session!(123)
      %Session{}

      iex> get_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Creates a session.

  ## Examples

      iex> create_session(%{field: value})
      {:ok, %Session{}}

      iex> create_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a session.

  ## Examples

      iex> update_session(session, %{field: new_value})
      {:ok, %Session{}}

      iex> update_session(session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Session.

  ## Examples

      iex> delete_session(session)
      {:ok, %Session{}}

      iex> delete_session(session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking session changes.

  ## Examples

      iex> change_session(session)
      %Ecto.Changeset{source: %Session{}}

  """
  def change_session(%Session{} = session) do
    Session.changeset(session, %{})
  end

  alias Mobilizon.Events.Track

  @doc """
  Returns the list of tracks.

  ## Examples

      iex> list_tracks()
      [%Track{}, ...]

  """
  def list_tracks do
    Repo.all(Track)
  end

  @doc """
  Returns the list of sessions for a track
  """
  @spec list_sessions_for_track(Track.t()) :: list(Session.t())
  def list_sessions_for_track(%Track{id: track_id}) do
    Repo.all(from(s in Session, where: s.track_id == ^track_id))
  end

  @doc """
  Gets a single track.

  Raises `Ecto.NoResultsError` if the Track does not exist.

  ## Examples

      iex> get_track!(123)
      %Track{}

      iex> get_track!(456)
      ** (Ecto.NoResultsError)

  """
  def get_track!(id), do: Repo.get!(Track, id)

  @doc """
  Creates a track.

  ## Examples

      iex> create_track(%{field: value})
      {:ok, %Track{}}

      iex> create_track(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a track.

  ## Examples

      iex> update_track(track, %{field: new_value})
      {:ok, %Track{}}

      iex> update_track(track, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Track.

  ## Examples

      iex> delete_track(track)
      {:ok, %Track{}}

      iex> delete_track(track)
      {:error, %Ecto.Changeset{}}

  """
  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking track changes.

  ## Examples

      iex> change_track(track)
      %Ecto.Changeset{source: %Track{}}

  """
  def change_track(%Track{} = track) do
    Track.changeset(track, %{})
  end

  alias Mobilizon.Events.Comment

  @doc """
  Returns the list of public comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(from(c in Comment, where: c.visibility == ^:public))
  end

  def get_public_comments_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    query =
      from(
        c in Comment,
        where: c.actor_id == ^actor_id and c.visibility in [^:public, ^:unlisted],
        order_by: [desc: :id],
        preload: [
          :actor,
          :in_reply_to_comment,
          :origin_comment,
          :event
        ]
      )
      |> paginate(page, limit)

    comments = Repo.all(query)

    count_comments =
      Repo.one(from(c in Comment, select: count(c.id), where: c.actor_id == ^actor_id))

    {:ok, comments, count_comments}
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  # @doc """
  # Gets a single comment from it's UUID

  # """
  # @spec get_comment_from_uuid(String.t) :: {:ok, Comment.t} | {:error, nil}
  # def get_comment_from_uuid(uuid), do: Repo.get_by(Comment, uuid: uuid)

  # @doc """
  # Gets a single comment by it's UUID.

  # Raises `Ecto.NoResultsError` if the Comment does not exist.

  # ## Examples

  #     iex> get_comment_from_uuid!("123AFV13")
  #     %Comment{}

  #     iex> get_comment_from_uuid!("20R9HKDJHF")
  #     ** (Ecto.NoResultsError)

  # """
  # @spec get_comment_from_uuid(String.t) :: Comment.t
  # def get_comment_from_uuid!(uuid), do: Repo.get_by!(Comment, uuid: uuid)

  def get_comment_full_from_uuid(uuid) do
    with %Comment{} = comment <- Repo.get_by!(Comment, uuid: uuid) do
      Repo.preload(comment, [:actor, :attributed_to, :in_reply_to_comment])
    end
  end

  def get_cached_comment_full_by_uuid(uuid) do
    Cachex.fetch(:activity_pub, "comment_" <> uuid, fn "comment_" <> uuid ->
      with %Comment{} = comment <- get_comment_full_from_uuid(uuid) do
        {:commit, comment}
      else
        _ -> {:ignore, nil}
      end
    end)
  end

  def get_comment_from_url(url), do: Repo.get_by(Comment, url: url)

  def get_comment_from_url!(url), do: Repo.get_by!(Comment, url: url)

  def get_comment_full_from_url(url) do
    case Repo.one(
           from(c in Comment, where: c.url == ^url, preload: [:actor, :in_reply_to_comment])
         ) do
      nil -> {:error, :comment_not_found}
      comment -> {:ok, comment}
    end
  end

  def get_comment_full_from_url!(url) do
    with %Comment{} = comment <- Repo.get_by!(Comment, url: url) do
      Repo.preload(comment, [:actor, :in_reply_to_comment])
    end
  end

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{source: %Comment{}}

  """
  def change_comment(%Comment{} = comment) do
    Comment.changeset(comment, %{})
  end
end
