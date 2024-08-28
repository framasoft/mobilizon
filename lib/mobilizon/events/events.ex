defmodule Mobilizon.Events do
  @moduledoc """
  The Events context.
  """

  import Geo.PostGIS

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Service.Guards
  import Mobilizon.Storage.Ecto
  import Mobilizon.Events.Utils, only: [calculate_notification_time: 1]

  alias Ecto.{Changeset, Multi}

  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Config

  alias Mobilizon.Events.{
    Event,
    EventParticipantStats,
    FeedToken,
    Participant,
    Session,
    Tag,
    TagRelation,
    Track
  }

  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.Export.Cachable
  alias Mobilizon.Service.Workers.BuildSearch
  alias Mobilizon.Service.Workers.EventDelayedNotificationWorker
  alias Mobilizon.Share
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.{Setting, User}

  defenum(EventVisibility, :event_visibility, [
    :public,
    :unlisted,
    :restricted,
    :private
  ])

  defenum(JoinOptions, :join_options, [
    :free,
    :restricted,
    :invite,
    :external
  ])

  defenum(EventStatus, :event_status, [
    :tentative,
    :confirmed,
    :cancelled
  ])

  defenum(ParticipantRole, :participant_role, [
    :not_approved,
    :not_confirmed,
    :rejected,
    :participant,
    :moderator,
    :administrator,
    :creator
  ])

  @public_visibility [:public, :unlisted]

  @event_preloads [
    :organizer_actor,
    :attributed_to,
    :mentions,
    :sessions,
    :tracks,
    :tags,
    :comments,
    :participants,
    :physical_address,
    :picture,
    :contacts,
    :media
  ]

  @participant_preloads [:event, :actor]

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
    |> preload_for_event()
    |> Repo.one!()
  end

  @doc """
  Gets an event by its URL, with all associations loaded.
  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  @spec get_public_event_by_url_with_preload!(String.t()) :: Event.t()
  def get_public_event_by_url_with_preload!(url) do
    url
    |> event_by_url_query()
    |> filter_unlisted_and_public_visibility()
    |> filter_draft()
    |> preload_for_event()
    |> Repo.one!()
  end

  @doc """
  Gets a public event by its UUID, with all associations loaded.
  """
  @spec get_public_event_by_uuid_with_preload(String.t()) :: Event.t() | nil
  def get_public_event_by_uuid_with_preload(uuid) do
    uuid
    |> event_by_uuid_query()
    |> filter_unlisted_and_public_visibility()
    |> filter_draft()
    |> preload_for_event()
    |> Repo.one()
  end

  @spec check_if_event_has_instance_follow(String.t(), integer()) :: boolean()
  def check_if_event_has_instance_follow(event_uri, follower_actor_id) do
    Share
    |> join(:inner, [s], f in Follower, on: f.target_actor_id == s.actor_id)
    |> where([s, f], f.actor_id == ^follower_actor_id and s.uri == ^event_uri)
    |> Repo.exists?()
  end

  @doc """
  Gets an event by its UUID, with all associations loaded.
  """
  @spec get_event_by_uuid_with_preload(String.t()) :: Event.t() | nil
  def get_event_by_uuid_with_preload(uuid) do
    uuid
    |> event_by_uuid_query()
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
    |> filter_draft()
    |> Repo.one()
  end

  @doc """
  Creates an event.
  """
  @spec create_event(map) ::
          {:ok, Event.t()}
          | {:error, Changeset.t()}
          | {:error, :update | :write, Changeset.t(), map()}
  def create_event(attrs \\ %{}) do
    with {:ok, %{insert: %Event{} = event}} <- do_create_event(attrs),
         %Event{} = event <- Repo.preload(event, @event_preloads) do
      unless event.draft do
        BuildSearch.enqueue(:insert_search_event, %{"event_id" => event.id})
      end

      {:ok, event}
    else
      err -> err
    end
  end

  # We start by inserting the event and then insert a first participant if the event is not a draft
  @spec do_create_event(map) ::
          {:ok, %{insert: Event.t(), write: Participant.t() | nil}}
          | {:error, Changeset.t()}
          | {:error, :update | :write, Changeset.t(), map()}
  defp do_create_event(attrs) do
    Multi.new()
    |> Multi.insert(:insert, Event.changeset(%Event{}, attrs))
    |> Multi.run(:write, fn _repo, %{insert: %Event{draft: draft} = event} ->
      with {:is_draft, false} <- {:is_draft, draft},
           {:ok, %Participant{} = participant} <-
             create_participant(
               %{
                 event_id: event.id,
                 role: :creator,
                 actor_id: event.organizer_actor_id
               },
               false
             ) do
        {:ok, participant}
      else
        {:is_draft, true} -> {:ok, nil}
        err -> err
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates an event.

  We start by updating the event and then insert a first participant if the event is not a draft anymore
  """
  @spec update_event(Event.t(), map) ::
          {:ok, Event.t()}
          | {:error, Changeset.t()}
          | {:error, :update | :write, Changeset.t(), map()}
  def update_event(%Event{draft: old_draft} = old_event, attrs) do
    with %Event{} = old_event <- Repo.preload(old_event, @event_preloads),
         %Changeset{changes: changes} = changeset <-
           Event.update_changeset(old_event, attrs),
         {:ok, %{update: %Event{} = new_event}} <-
           Multi.new()
           |> Multi.update(:update, changeset)
           |> Multi.run(:write, fn _repo, %{update: %Event{draft: draft} = event} ->
             with {:was_draft, true} <- {:was_draft, old_draft == true && draft == false},
                  {:ok, %Participant{} = participant} <-
                    create_participant(
                      %{
                        event_id: event.id,
                        role: :creator,
                        actor_id: event.organizer_actor_id
                      },
                      false
                    ) do
               {:ok, participant}
             else
               {:was_draft, false} -> {:ok, nil}
               err -> err
             end
           end)
           |> Repo.transaction(),
         %Event{} = new_event <- Repo.preload(new_event, @event_preloads, force: true) do
      Cachable.clear_all_caches(new_event)

      unless new_event.draft do
        %{
          action: :notify_of_event_update,
          event_uuid: new_event.uuid,
          old_event: old_event |> Map.from_struct() |> Map.take(Event.__schema__(:fields)),
          changes: build_changes(changes)
        }
        |> EventDelayedNotificationWorker.new(
          scheduled_at: calculate_notification_time(new_event.begins_on),
          replace: [:scheduled_at, :args],
          unique: [period: 1, keys: [:event_uuid, :action]]
        )
        |> Oban.insert()

        BuildSearch.enqueue(:update_search_event, %{"event_id" => new_event.id})
      end

      {:ok, new_event}
    end
  end

  @spec build_changes(map()) :: map()
  defp build_changes(changes) do
    changes
    |> maybe_add_field(:physical_address)
    |> maybe_add_field(:options)
    |> maybe_add_field(:metadata)
    |> Map.drop(Event.__schema__(:associations) -- [:physical_address, :options, :metadata])
  end

  @spec maybe_add_field(map(), atom()) :: map()
  defp maybe_add_field(changes, field) do
    case Map.get(changes, field) do
      %Ecto.Changeset{} = changeset ->
        Map.put(
          changes,
          field,
          changeset
          |> Ecto.Changeset.apply_changes()
          |> Map.from_struct()
          |> Map.take(Address.__schema__(:fields))
        )

      _ ->
        Map.drop(changes, [field])
    end
  end

  @doc """
  Deletes an event.
  """
  @spec delete_event(Event.t()) :: {:ok, Event.t()} | {:error, Changeset.t()}
  def delete_event(%Event{} = event) do
    Cachable.clear_all_caches(event)
    Repo.delete(event)
  end

  @doc """
  Returns the list of events.
  """
  @spec list_events(
          integer | nil,
          integer | nil,
          atom,
          atom,
          boolean,
          boolean | nil,
          string | nil,
          float | nil
        ) :: Page.t(Event.t())
  def list_events(
        page \\ nil,
        limit \\ nil,
        sort \\ :begins_on,
        direction \\ :asc,
        is_future \\ true,
        longevents \\ nil,
        location \\ nil,
        radius \\ nil
      ) do
    Event
    |> distinct([e], [{^direction, ^sort}, asc: e.id])
    |> preload([:organizer_actor, :participants])
    |> sort(sort, direction)
    |> maybe_join_address(%{location: location, radius: radius})
    |> events_for_location(%{location: location, radius: radius})
    |> filter_future_events(is_future)
    |> events_for_longevents(longevents)
    |> filter_public_visibility()
    |> filter_draft()
    |> filter_cancelled_events()
    |> filter_local_or_from_followed_instances_events()
    |> Page.build_page(page, limit)
  end

  @spec stream_events_for_sitemap :: Enum.t()
  def stream_events_for_sitemap do
    Event
    |> filter_public_visibility()
    |> filter_draft()
    |> filter_local()
    |> Repo.stream()
  end

  @spec list_public_local_events(integer | nil, integer | nil, atom | nil, atom | nil) ::
          Page.t(Event.t())
  def list_public_local_events(page \\ nil, limit \\ nil, sort \\ nil, direction \\ nil) do
    Event
    |> filter_public_visibility()
    |> filter_draft()
    |> filter_local()
    |> preload_for_event()
    |> event_order_by(sort, direction)
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of events with the same tags.
  """
  @spec list_events_by_tags([Tag.t()], integer) :: [Event.t()]
  def list_events_by_tags(tags, limit \\ 2) do
    tags
    |> Enum.map(& &1.id)
    |> events_by_tags_query(limit)
    |> filter_draft()
    |> Repo.all()
  end

  @doc """
  Lists public events for the actor, with all associations loaded.
  """
  @spec list_public_events_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t(Event.t())
  def list_public_events_for_actor(actor, page \\ nil, limit \\ nil)

  def list_public_events_for_actor(%Actor{type: :Group} = group, page, limit),
    do: list_organized_events_for_group(group, :public, nil, nil, nil, nil, page, limit)

  def list_public_events_for_actor(%Actor{id: actor_id}, page, limit) do
    actor_id
    |> do_list_public_events_for_actor()
    |> Page.build_page(page, limit)
  end

  @doc """
  Lists public upcoming events for the actor, with all associations loaded.
  """
  @spec list_public_upcoming_events_for_actor(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Event.t())
  def list_public_upcoming_events_for_actor(actor, page \\ nil, limit \\ nil)

  def list_public_upcoming_events_for_actor(%Actor{type: :Group} = group, page, limit),
    do:
      list_organized_events_for_group(
        group,
        :public,
        DateTime.utc_now(),
        nil,
        nil,
        nil,
        page,
        limit
      )

  def list_public_upcoming_events_for_actor(%Actor{id: actor_id}, page, limit) do
    actor_id
    |> do_list_public_events_for_actor()
    |> event_filter_begins_on(DateTime.utc_now(), nil)
    |> Page.build_page(page, limit)
  end

  @spec do_list_public_events_for_actor(integer()) :: Ecto.Query.t()
  defp do_list_public_events_for_actor(actor_id) do
    actor_id
    |> event_for_actor_query()
    |> filter_public_visibility()
    |> filter_draft()
    |> preload_for_event()
  end

  @spec list_organized_events_for_actor(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Event.t())
  def list_organized_events_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> event_for_actor_query(desc: :begins_on)
    |> preload_for_event()
    |> Page.build_page(page, limit)
  end

  @spec list_simple_organized_events_for_group(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Event.t())
  def list_simple_organized_events_for_group(%Actor{} = actor, page \\ nil, limit \\ nil) do
    list_organized_events_for_group(actor, :all, nil, nil, nil, nil, page, limit)
  end

  @spec list_organized_events_for_group(
          Actor.t(),
          :public | :all,
          DateTime.t() | nil,
          DateTime.t() | nil,
          atom() | nil,
          atom() | nil,
          integer | nil,
          integer | nil
        ) :: Page.t(Event.t())
  def list_organized_events_for_group(
        %Actor{id: group_id},
        visibility \\ :public,
        after_datetime \\ nil,
        before_datetime \\ nil,
        order_by \\ nil,
        order_direction \\ nil,
        page \\ nil,
        limit \\ nil
      ) do
    group_id
    |> event_for_group_query()
    |> event_filter_visibility(visibility)
    |> event_filter_begins_on(after_datetime, before_datetime)
    |> event_order_by(order_by, order_direction)
    |> preload_for_event()
    |> Page.build_page(page, limit)
  end

  @spec list_drafts_for_user(integer, integer | nil, integer | nil) :: Page.t(Event.t())
  def list_drafts_for_user(user_id, page \\ nil, limit \\ nil) do
    Event
    |> user_events_query(user_id)
    |> filter_draft(true)
    |> order_by(desc: :updated_at)
    |> Page.build_page(page, limit)
  end

  @spec user_moderator_for_event?(integer | String.t(), integer | String.t()) :: boolean
  def user_moderator_for_event?(user_id, event_id) do
    Participant
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> where([p, _a], p.event_id == ^event_id)
    |> where([_p, a], a.user_id == ^user_id)
    |> where([p, _a], p.role == ^:creator)
    |> Repo.exists?()
  end

  @doc """
  Finds close events to coordinates.
  Radius is in meters and defaults to 50km.
  """
  @spec find_close_events(float(), float(), non_neg_integer()) :: [Event.t()]
  def find_close_events(lon, lat, radius \\ 50_000) do
    "SRID=#{4326};POINT(#{lon} #{lat})"
    |> Geo.WKT.decode!()
    |> close_events_query(radius)
    |> filter_draft()
    |> Repo.all()
  end

  @doc """
  Counts local events.
  """
  @spec count_local_events :: integer
  def count_local_events do
    count_local_events_query()
    |> filter_unlisted_and_public_visibility()
    |> filter_draft()
    |> Repo.one()
  end

  @doc """
  Counts all events.
  """
  @spec count_events :: integer
  def count_events do
    count_events_query()
    |> filter_unlisted_and_public_visibility()
    |> filter_draft()
    |> Repo.one()
  end

  @doc """
  Builds a page struct for events by their name.
  """
  @spec build_events_for_search(map(), integer | nil, integer | nil) :: Page.t(Event.t())
  def build_events_for_search(%{term: term} = args, page \\ nil, limit \\ nil) do
    search_string = normalize_search_string(term)

    search_string
    |> events_for_search_query()
    |> events_for_begins_on(Map.get(args, :begins_on, DateTime.utc_now()))
    |> events_for_ends_on(Map.get(args, :ends_on))
    |> events_for_longevents(Map.get(args, :longevents))
    |> events_for_category(args)
    |> events_for_categories(args)
    |> events_for_languages(args)
    |> events_for_statuses(args)
    |> events_for_tags(args)
    |> maybe_join_address(args)
    |> events_for_location(args)
    |> events_for_bounding_box(args)
    |> filter_online(args)
    |> filter_draft()
    |> filter_local(if Map.get(args, :local_only, nil) == true, do: true, else: nil)
    |> filter_local_or_from_followed_instances_events()
    |> filter_public_visibility()
    |> event_order(Map.get(args, :sort_by, :match_desc), search_string)
    |> Page.build_page(page, limit, :begins_on)
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
  Gets a tag by its title.
  """
  @spec get_tag_by_title(String.t()) :: Tag.t() | nil
  def get_tag_by_title(slug) do
    slug
    |> tag_by_title_query()
    |> Repo.one()
  end

  @doc """
  Creates a tag.
  """
  @spec create_tag(map) :: {:ok, Tag.t()} | {:error, Changeset.t()}
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.
  """
  @spec update_tag(Tag.t(), map) :: {:ok, Tag.t()} | {:error, Changeset.t()}
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.
  """
  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Changeset.t()}
  def delete_tag(%Tag{} = tag), do: Repo.delete(tag)

  @doc """
  Returns the list of tags.
  """
  @spec list_tags(String.t() | nil, integer | nil, integer | nil) :: Page.t(Tag.t())
  def list_tags(filter \\ nil, page \\ nil, limit \\ nil) do
    Tag
    |> tag_filter(filter)
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
  @spec are_tags_linked?(Tag.t(), Tag.t()) :: boolean
  def are_tags_linked?(%Tag{id: tag1_id}, %Tag{id: tag2_id}) do
    tag_relation =
      tag1_id
      |> tags_linked_query(tag2_id)
      |> Repo.one()

    !!tag_relation
  end

  @doc """
  Creates a relation between two tags.
  """
  @spec create_tag_relation(map) :: {:ok, TagRelation.t()} | {:error, Changeset.t()}
  def create_tag_relation(attrs) do
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
          {:ok, TagRelation.t()} | {:error, Changeset.t()}
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

  ## Examples

      iex> get_participant(123)
      %Participant{}

      iex> get_participant(456)
      nil

  """
  @spec get_participant(integer) :: Participant.t() | nil
  @spec get_participant(integer | String.t(), integer | String.t(), map()) ::
          {:ok, Participant.t()} | {:error, :participant_not_found}
  def get_participant(participant_id) do
    Participant
    |> where([p], p.id == ^participant_id)
    |> preload([p], ^@participant_preloads)
    |> Repo.one()
  end

  @doc """
  Gets a single participation for an event and actor.
  """
  def get_participant(event_id, actor_id, params \\ %{})

  # This one if to check someone doesn't go to the same event twice
  def get_participant(event_id, actor_id, %{email: email}) do
    case Participant
         |> where([p], event_id: ^event_id, actor_id: ^actor_id)
         |> where([p], fragment("? ->>'email' = ?", p.metadata, ^email))
         |> preload([p], ^@participant_preloads)
         |> Repo.one() do
      %Participant{} = participant ->
        {:ok, participant}

      nil ->
        {:error, :participant_not_found}
    end
  end

  # This one if for finding participants by their cancellation token when wanting to cancel a participation
  def get_participant(event_id, actor_id, %{cancellation_token: cancellation_token}) do
    case Participant
         |> where([p], event_id: ^event_id, actor_id: ^actor_id)
         |> where([p], fragment("? ->>'cancellation_token' = ?", p.metadata, ^cancellation_token))
         |> preload([p], ^@participant_preloads)
         |> Repo.one() do
      %Participant{} = participant ->
        {:ok, participant}

      nil ->
        {:error, :participant_not_found}
    end
  end

  def get_participant(event_id, actor_id, _params) do
    case Participant
         |> Repo.get_by(event_id: event_id, actor_id: actor_id)
         |> Repo.preload(@participant_preloads) do
      %Participant{} = participant ->
        {:ok, participant}

      nil ->
        {:error, :participant_not_found}
    end
  end

  @spec get_participant_by_confirmation_token(String.t()) :: Participant.t() | nil
  def get_participant_by_confirmation_token(confirmation_token) do
    Participant
    |> where([p], fragment("? ->>'confirmation_token' = ?", p.metadata, ^confirmation_token))
    |> preload([p], ^@participant_preloads)
    |> Repo.one()
  end

  @spec get_participant!(integer | String.t()) :: Participant.t()
  def get_participant!(participant_id) do
    Repo.get_by!(Participant, id: participant_id)
  end

  @doc """
  Gets a single participation for an event and actor.

  Raises `Ecto.NoResultsError` if the Participant does not exist.

  ## Examples

      iex> get_participant!(123, 19)
      %Participant{}

      iex> get_participant!(456, 5)
      ** (Ecto.NoResultsError)

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
  Returns the number of participations for all local events
  """
  @spec count_confirmed_participants_for_local_events :: integer()
  def count_confirmed_participants_for_local_events do
    count_confirmed_participants_for_local_events_query()
    |> Repo.one()
  end

  @doc """
  Returns the list of participants for an event.
  Default behaviour is to not return :not_approved or :not_confirmed participants
  """
  @spec list_participants_for_event(String.t(), list(atom()), integer | nil, integer | nil) ::
          Page.t(Participant.t())
  def list_participants_for_event(
        id,
        roles \\ [],
        page \\ nil,
        limit \\ nil
      ) do
    id
    |> participants_for_event_query(roles)
    |> preload([:actor, :event])
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the whole list of participants for an event.
  Default behaviour is to not return :not_approved or :not_confirmed participants
  """
  @spec list_all_participants_for_event(String.t(), list(atom())) :: list(Participant.t())
  def list_all_participants_for_event(
        id,
        roles \\ []
      ) do
    id
    |> participants_for_event_query(roles)
    |> preload([:actor, :event])
    |> Repo.all()
  end

  @spec list_actors_participants_for_event(String.t()) :: [Actor.t()]
  def list_actors_participants_for_event(id) do
    id
    |> list_participant_actors_for_event_query
    |> Repo.all()
  end

  @doc """
  Returns the list of participations for an actor.

  Default behaviour is to not return :not_approved participants

  ## Examples

      iex> list_event_participations_for_user(5)
      [%Participant{}, ...]

  """
  @spec list_participations_for_user(
          integer,
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer | nil,
          integer | nil
        ) :: Page.t(Participant.t())
  def list_participations_for_user(user_id, after_datetime, before_datetime, page, limit) do
    user_id
    |> list_participations_for_user_query()
    |> participation_filter_begins_on(after_datetime, before_datetime)
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of organizers participants for an event.

  ## Examples

      iex> list_organizers_participants_for_event(id)
      [%Participant{role: :creator}, ...]
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
          Page.t(Participant.t())
  def list_event_participations_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> event_participations_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of upcoming participations for an actor.
  """
  @spec list_upcoming_event_participations_for_actor(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Participant.t())
  def list_upcoming_event_participations_for_actor(
        %Actor{id: actor_id},
        page \\ nil,
        limit \\ nil
      ) do
    actor_id
    |> event_participations_for_actor_query(DateTime.utc_now())
    |> Page.build_page(page, limit)
  end

  @doc """
  Counts participant participants (participants with no extra role)
  """
  @spec count_participant_participants(integer | String.t()) :: integer
  def count_participant_participants(event_id) do
    event_id
    |> count_participants_query()
    |> filter_participant_role()
    |> Repo.aggregate(:count, :id)
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
  @spec create_participant(map) ::
          {:ok, Participant.t()}
          | {:error, :participant | :update_event_participation_stats, Changeset.t(), map()}
  def create_participant(attrs \\ %{}, update_event_participation_stats \\ true) do
    with {:ok, %{participant: %Participant{} = participant}} <-
           Multi.new()
           |> Multi.insert(:participant, Participant.changeset(%Participant{}, attrs))
           |> Multi.run(:update_event_participation_stats, fn _repo,
                                                              %{
                                                                participant:
                                                                  %Participant{role: new_role} =
                                                                    participant
                                                              } ->
             update_participant_stats(
               participant,
               nil,
               new_role,
               update_event_participation_stats
             )
           end)
           |> Repo.transaction() do
      {:ok, Repo.preload(participant, [:event, :actor])}
    end
  end

  @doc """
  Updates a participant.
  """
  @spec update_participant(Participant.t(), map) ::
          {:ok, Participant.t()}
          | {:error, :participant | :update_event_participation_stats, Changeset.t(), map()}
  def update_participant(%Participant{role: old_role} = participant, attrs) do
    with {:ok, %{participant: %Participant{} = participant}} <-
           Multi.new()
           |> Multi.update(:participant, Participant.changeset(participant, attrs))
           |> Multi.run(:update_event_participation_stats, fn _repo,
                                                              %{
                                                                participant:
                                                                  %Participant{role: new_role} =
                                                                    participant
                                                              } ->
             update_participant_stats(participant, old_role, new_role)
           end)
           |> Repo.transaction() do
      {:ok, Repo.preload(participant, [:event, :actor])}
    end
  end

  @doc """
  Deletes a participant.
  """
  @spec delete_participant(Participant.t()) ::
          {:ok, %{participant: Participant.t()}}
          | {:error, :participant | :update_event_participation_stats, Changeset.t(), map()}
  def delete_participant(%Participant{role: old_role} = participant) do
    Multi.new()
    |> Multi.delete(:participant, participant)
    |> Multi.run(:update_event_participation_stats, fn _repo,
                                                       %{
                                                         participant: %Participant{} = participant
                                                       } ->
      update_participant_stats(participant, old_role, nil)
    end)
    |> Repo.transaction()
  end

  defp update_participant_stats(
         %Participant{
           event_id: event_id
         } = _participant,
         old_role,
         new_role,
         update_event_participation_stats \\ true
       ) do
    with {:update_event_participation_stats, true} <-
           {:update_event_participation_stats, update_event_participation_stats},
         {:ok, %Event{} = event} <- get_event_with_preload(event_id),
         %EventParticipantStats{} = participant_stats <-
           Map.get(event, :participant_stats),
         %EventParticipantStats{} = participant_stats <-
           do_update_participant_stats(participant_stats, old_role, new_role),
         {:ok, %Event{} = event} <-
           event
           |> Event.update_changeset(%{
             participant_stats: Map.from_struct(participant_stats)
           })
           |> Repo.update() do
      {:ok, event}
    else
      {:update_event_participation_stats, false} ->
        {:ok, nil}

      {:error, :event_not_found} ->
        {:error, :event_not_found}

      err ->
        {:error, err}
    end
  end

  defp do_update_participant_stats(participant_stats, old_role, new_role) do
    participant_stats
    |> decrease_participant_stats(old_role)
    |> increase_participant_stats(new_role)
  end

  defp increase_participant_stats(participant_stats, nil), do: participant_stats

  defp increase_participant_stats(participant_stats, role),
    do: Map.update(participant_stats, role, 1, &(&1 + 1))

  defp decrease_participant_stats(participant_stats, nil), do: participant_stats

  defp decrease_participant_stats(participant_stats, role),
    do: Map.update(participant_stats, role, 0, &(&1 - 1))

  @doc """
  Gets a single session.
  Raises `Ecto.NoResultsError` if the session does not exist.
  """
  @spec get_session!(integer | String.t()) :: Session.t()
  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Creates a session.
  """
  @spec create_session(map) :: {:ok, Session.t()} | {:error, Changeset.t()}
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a session.
  """
  @spec update_session(Session.t(), map) :: {:ok, Session.t()} | {:error, Changeset.t()}
  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a session.
  """
  @spec delete_session(Session.t()) :: {:ok, Session.t()} | {:error, Changeset.t()}
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
  @spec create_track(map) :: {:ok, Track.t()} | {:error, Changeset.t()}
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a track.
  """
  @spec update_track(Track.t(), map) :: {:ok, Track.t()} | {:error, Changeset.t()}
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a track.
  """
  @spec delete_track(Track.t()) :: {:ok, Track.t()} | {:error, Changeset.t()}
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
  Gets a single feed token.
  """
  @spec get_feed_token(String.t()) :: FeedToken.t() | nil
  def get_feed_token(token) do
    token
    |> feed_token_query()
    |> Repo.one()
  end

  @doc """
  Creates a feed token.
  """
  @spec create_feed_token(map) :: {:ok, FeedToken.t()} | {:error, Changeset.t()}
  def create_feed_token(attrs \\ %{}) do
    attrs = Map.put(attrs, :token, Ecto.UUID.generate())

    %FeedToken{}
    |> FeedToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a feed token.
  """
  @spec delete_feed_token(FeedToken.t()) :: {:ok, FeedToken.t()} | {:error, Changeset.t()}
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
  defp event_for_actor_query(actor_id, order_by \\ [desc: :id]) do
    Event
    |> where([e], e.organizer_actor_id == ^actor_id)
    |> order_by([e], ^order_by)
  end

  @spec event_for_group_query(integer | String.t()) :: Ecto.Query.t()
  defp event_for_group_query(group_id) do
    where(Event, [e], e.attributed_to_id == ^group_id)
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

  @spec user_events_query(Ecto.Queryable.t(), number()) :: Ecto.Query.t()
  defp user_events_query(query, user_id) do
    from(
      e in query,
      join: a in Actor,
      on: a.id == e.organizer_actor_id,
      where: a.user_id == ^user_id
    )
  end

  defmacro matching_event_ids_and_ranks(search_string) do
    quote do
      fragment(
        """
        SELECT event_search.id AS id,
        ts_rank(
          event_search.document, plainto_tsquery(unaccent(?))
        ) AS rank
        FROM event_search
        WHERE event_search.document @@ plainto_tsquery(unaccent(?))
        OR event_search.title ILIKE ?
        """,
        ^unquote(search_string),
        ^unquote(search_string),
        ^"%#{unquote(search_string)}%"
      )
    end
  end

  defp events_for_search_query(""), do: Event

  defp events_for_search_query(search_string) do
    join(Event, :inner, [e], id_and_rank in matching_event_ids_and_ranks(search_string),
      on: id_and_rank.id == e.id
    )
  end

  @spec events_for_begins_on(Ecto.Queryable.t(), DateTime.t() | nil) :: Ecto.Query.t()
  defp events_for_begins_on(query, begins_on) do
    if is_nil(begins_on) do
      query
    else
      where(
        query,
        [q],
        (not is_nil(q.ends_on) and q.ends_on > ^begins_on) or
          (is_nil(q.ends_on) and q.begins_on >= ^begins_on)
      )
    end
  end

  @spec events_for_ends_on(Ecto.Queryable.t(), DateTime.t() | nil) :: Ecto.Query.t()
  defp events_for_ends_on(query, ends_on) do
    if is_nil(ends_on) do
      query
    else
      where(
        query,
        [q],
        (is_nil(q.ends_on) and q.begins_on <= ^ends_on) or
          q.ends_on <= ^ends_on
      )
    end
  end

  @spec events_for_longevents(Ecto.Queryable.t(), Boolean.t() | nil) :: Ecto.Query.t()
  defp events_for_longevents(query, longevents) do
    duration = Config.get([:instance, :duration_of_long_event], 0)

    if duration <= 0 do
      query
    else
      case longevents do
        nil ->
          query

        true ->
          where(
            query,
            [q],
            not is_nil(q.ends_on) and
              q.ends_on > fragment("? + '1 days'::interval * ?", q.begins_on, ^duration)
          )

        false ->
          where(
            query,
            [q],
            is_nil(q.ends_on) or
              q.ends_on <= fragment("? + '1 days'::interval * ?", q.begins_on, ^duration)
          )
      end
    end
  end

  @spec events_for_category(Ecto.Queryable.t(), map()) :: Ecto.Query.t()
  defp events_for_category(query, %{category: category}) when is_valid_string(category) do
    where(query, [q], q.category == ^category)
  end

  defp events_for_category(query, _args), do: query

  @spec events_for_categories(Ecto.Queryable.t(), map()) :: Ecto.Query.t()
  defp events_for_categories(query, %{category_one_of: category_one_of})
       when length(category_one_of) > 0 do
    where(query, [q], q.category in ^category_one_of)
  end

  defp events_for_categories(query, _args), do: query

  defp events_for_languages(query, %{language_one_of: language_one_of})
       when length(language_one_of) > 0 do
    where(query, [q], q.language in ^language_one_of)
  end

  defp events_for_languages(query, _args), do: query

  defp events_for_statuses(query, %{status_one_of: status_one_of})
       when length(status_one_of) > 0 do
    where(query, [q], q.status in ^status_one_of)
  end

  defp events_for_statuses(query, _args), do: query

  @spec events_for_tags(Ecto.Queryable.t(), map()) :: Ecto.Query.t()
  defp events_for_tags(query, %{tags: tags}) when is_valid_string(tags) do
    query
    |> join(:inner, [q], te in "events_tags", on: q.id == te.event_id)
    |> join(:inner, [q, ..., te], t in Tag, on: te.tag_id == t.id)
    |> where([q, ..., t], t.title in ^String.split(tags, ",", trim: true))
  end

  defp events_for_tags(query, _args), do: query

  # We add the inner join on address only if we're going to use it in
  # events_for_location or events_for_bounding_box
  # So we're sure it's only being added once
  defp maybe_join_address(query, %{location: location, radius: radius})
       when is_valid_string(location) and not is_nil(radius) do
    join(query, :inner, [q], a in Address, on: a.id == q.physical_address_id, as: :address)
  end

  defp maybe_join_address(query, %{bbox: bbox}) when is_valid_string(bbox) do
    join(query, :inner, [q], a in Address, on: a.id == q.physical_address_id, as: :address)
  end

  defp maybe_join_address(query, _), do: query

  @spec events_for_location(Ecto.Queryable.t(), map()) :: Ecto.Query.t()
  defp events_for_location(query, %{radius: radius}) when is_nil(radius),
    do: query

  defp events_for_location(query, %{location: location, radius: radius})
       when is_valid_string(location) and not is_nil(radius) do
    with {lon, lat} <- Geohax.decode(location),
         point <- Geo.WKT.decode!("SRID=4326;POINT(#{lon} #{lat})"),
         {{x_min, y_min}, {x_max, y_max}} <- search_box({lon, lat}, radius) do
      where(
        query,
        [q, ..., a],
        st_x(a.geom) > ^x_min and st_x(a.geom) < ^x_max and
          st_y(a.geom) > ^y_min and st_y(a.geom) < ^y_max and
          st_dwithin_in_meters(^point, a.geom, ^(radius * 1000))
      )
    else
      _ -> query
    end
  end

  defp events_for_location(query, _args), do: query

  defp events_for_bounding_box(query, %{bbox: bbox}) when is_valid_string(bbox) do
    [top_left, bottom_right] = String.split(bbox, ":")
    [ymax, xmin] = String.split(top_left, ",")
    [ymin, xmax] = String.split(bottom_right, ",")

    where(
      query,
      [q, ..., a],
      fragment(
        "? @ ST_MakeEnvelope(?,?,?,?,?)",
        a.geom,
        ^sanitize_bounding_box_params(xmin),
        ^sanitize_bounding_box_params(ymin),
        ^sanitize_bounding_box_params(xmax),
        ^sanitize_bounding_box_params(ymax),
        "4326"
      )
    )
  end

  defp events_for_bounding_box(query, _args), do: query

  @spec sanitize_bounding_box_params(String.t()) :: float()
  defp sanitize_bounding_box_params(param) do
    param
    |> String.trim()
    |> String.to_float()
    |> Float.floor(10)
  end

  @spec search_box({float(), float()}, float()) :: {{float, float}, {float, float}}
  defp search_box({lon0, lat0}, radius) do
    km_per_lat_deg = 111.195
    lat_amp = radius / km_per_lat_deg
    km_per_lon_deg_at_lat = Haversine.distance({0.0, lat0}, {1.0, lat0}) / 1000
    lon_amp = radius / km_per_lon_deg_at_lat
    {{lon0 - lon_amp, lat0 - lat_amp}, {lon0 + lon_amp, lat0 + lat_amp}}
  end

  @spec filter_online(Ecto.Query.t(), map()) :: Ecto.Query.t()
  defp filter_online(query, %{type: :online}), do: online_fragment_check(query, true)

  defp filter_online(query, %{type: :in_person}), do: online_fragment_check(query, false)

  defp filter_online(query, _), do: query

  @spec online_fragment_check(Ecto.Query.t(), boolean()) :: Ecto.Query.t()
  defp online_fragment_check(query, value) do
    where(query, [q], fragment("(?->>'is_online')::bool = ?", q.options, ^value))
  end

  @spec normalize_search_string(String.t()) :: String.t()
  defp normalize_search_string(search_string) do
    search_string
    |> String.downcase()
    |> String.replace(~r/\n/, " ")
    |> String.replace(~r/\t/, " ")
    |> String.replace(~r/\s{2,}/, " ")
    |> String.trim()
  end

  @spec events_by_tags_query([integer], integer) :: Ecto.Query.t()
  def events_by_tags_query(tags_ids, limit) do
    from(
      e in Event,
      distinct: e.uuid,
      join: te in "events_tags",
      on: e.id == te.event_id,
      where: e.begins_on > ^DateTime.utc_now(),
      where: e.visibility == ^:public,
      where: te.tag_id in ^tags_ids,
      order_by: [asc: e.begins_on],
      limit: ^limit
    )
  end

  @spec count_local_events_query :: Ecto.Query.t()
  defp count_local_events_query do
    from(e in Event, select: count(e.id), where: e.local == ^true)
  end

  @spec count_events_query :: Ecto.Query.t()
  defp count_events_query do
    from(e in Event, select: count(e.id))
  end

  @spec tag_by_slug_query(String.t()) :: Ecto.Query.t()
  defp tag_by_slug_query(slug) do
    from(t in Tag, where: t.slug == ^slug)
  end

  @spec tag_by_title_query(String.t()) :: Ecto.Query.t()
  defp tag_by_title_query(title) do
    from(t in Tag, where: t.title == ^title, limit: 1)
  end

  @spec tag_filter(Ecto.Queryable.t(), String.t() | nil) :: Ecto.Query.t()
  defp tag_filter(query, nil), do: query
  defp tag_filter(query, ""), do: query

  defp tag_filter(query, filter) when is_binary(filter) do
    query
    |> where([q], ilike(q.slug, ^"%#{filter}%"))
    |> or_where([q], ilike(q.title, ^"%#{filter}%"))
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

  @spec tag_relation_union_subquery(Ecto.Queryable.t(), integer) :: Ecto.Query.t()
  defp tag_relation_union_subquery(subquery, tag_id) do
    from(
      tr in TagRelation,
      select: %{id: tr.link_id, weight: tr.weight},
      union_all: ^subquery,
      where: tr.tag_id == ^tag_id
    )
  end

  @spec tag_neighbors_query(Ecto.Queryable.t(), integer, integer) :: Ecto.Query.t()
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

  @spec count_participants_query(integer) :: Ecto.Query.t()
  def count_participants_query(event_id) do
    from(p in Participant, where: p.event_id == ^event_id)
  end

  @spec event_participations_for_actor_query(integer, DateTime.t() | nil) :: Ecto.Query.t()
  defp event_participations_for_actor_query(actor_id, after_date \\ nil)

  defp event_participations_for_actor_query(actor_id, nil) do
    do_event_participations_for_actor_query(actor_id)
  end

  defp event_participations_for_actor_query(actor_id, %DateTime{} = after_date) do
    actor_id
    |> do_event_participations_for_actor_query()
    |> where([_p, e], e.begins_on > ^after_date)
  end

  defp do_event_participations_for_actor_query(actor_id) do
    Participant
    |> join(:inner, [p], e in Event, on: p.event_id == e.id)
    |> where([p], p.actor_id == ^actor_id and p.role != ^:not_approved)
    |> order_by([_p, e], desc: e.begins_on)
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

  @spec count_confirmed_participants_for_local_events_query :: Ecto.Query.t()
  defp count_confirmed_participants_for_local_events_query do
    Participant
    |> join(:inner, [p], e in Event, on: p.event_id == e.id)
    |> where([p, e], e.local and p.role not in [^:not_approved, ^:not_confirmed, ^:rejected])
    |> select([p], count(p.id))
  end

  @spec list_participants_for_event_query(String.t()) :: Ecto.Query.t()
  defp list_participants_for_event_query(event_id) do
    Participant
    |> where([p], p.event_id == ^event_id)
  end

  @spec list_participant_actors_for_event_query(String.t()) :: Ecto.Query.t()
  defp list_participant_actors_for_event_query(event_id) do
    from(
      a in Actor,
      join: p in Participant,
      on: p.actor_id == a.id,
      where: p.event_id == ^event_id
    )
  end

  @spec participants_for_event_query(String.t(), list(atom())) :: Ecto.Query.t()
  def participants_for_event_query(id, roles \\ []) do
    id
    |> list_participants_for_event_query()
    |> filter_role(roles)
    |> order_by(asc: :role)
  end

  def participant_for_event_export_query(id, roles) do
    id
    |> participants_for_event_query(roles)
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> select([p, a], {p, a})
  end

  @doc """
  List emails for local users (including anonymous ones) participating to an event

  Returns {participation, actor, user, user_settings}
  """
  @spec list_local_emails_user_participants_for_event_query(String.t()) :: Ecto.Query.t()
  def list_local_emails_user_participants_for_event_query(event_id) do
    Participant
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id and is_nil(a.domain))
    |> join(:left, [_p, a], u in User, on: a.user_id == u.id)
    |> join(:left, [_p, _a, u], s in Setting, on: s.user_id == u.id)
    |> where(
      [p],
      p.event_id == ^event_id and p.role not in [^:not_approved, ^:not_confirmed, ^:rejected]
    )
    |> select([p, a, u, s], {p, a, u, s})
  end

  @doc """
  List anonymous participations to an event
  """
  @spec list_anonymous_participants_for_event(String.t()) :: [Participant.t()]
  def list_anonymous_participants_for_event(event_id) do
    Participant
    |> where(
      [p],
      p.event_id == ^event_id and p.role not in [^:not_approved, ^:not_confirmed, ^:rejected]
    )
    |> Repo.all()
  end

  @spec category_statistics :: [{String.t(), non_neg_integer()}]
  def category_statistics do
    Event
    |> filter_future_events(true)
    |> filter_public_visibility()
    |> filter_draft()
    |> filter_cancelled_events()
    |> filter_local_or_from_followed_instances_events()
    |> group_by([e], e.category)
    |> select([e], {e.category, count(e.id)})
    |> Repo.all()
  end

  @threshold_related_value 7

  @spec related_events(Event.t()) :: list(Event.t())
  def related_events(%Event{
        id: event_id,
        tags: tags,
        physical_address: physical_address,
        organizer_actor: %Actor{id: organizer_actor_id},
        attributed_to: attributed_to,
        category: category,
        language: language
      }) do
    event_tags_ids = Enum.map(tags, & &1.id)
    geom = if is_nil(physical_address), do: nil, else: physical_address.geom
    group_id = if is_nil(attributed_to), do: nil, else: attributed_to.id

    Event
    |> distinct([e], e.id)
    |> join(:left, [e], et in "events_tags", on: e.id == et.event_id)
    |> join(:left, [e], a in Address, on: e.physical_address_id == a.id)
    |> filter_future_events(true)
    |> filter_draft()
    |> filter_local_or_from_followed_instances_events()
    |> filter_public_visibility()
    |> where(
      [e, et, a],
      fragment(
        "(? = ?)::int * 5 + (? = ALL(?))::int * 2 + (? = ?)::int + (? = ?)::int * 2 + (?::int is null or ? = ?)::int * 2 + (?::geography is null or ST_DWithin(?::geography, ?::geography, ?::float))::int * 2 > ?",
        e.language,
        ^language,
        et.tag_id,
        ^event_tags_ids,
        e.category,
        ^category,
        e.organizer_actor_id,
        ^organizer_actor_id,
        ^group_id,
        e.attributed_to_id,
        ^group_id,
        ^geom,
        ^geom,
        a.geom,
        5000,
        @threshold_related_value
      )
    )
    |> where([e], e.id != ^event_id)
    |> order_by(
      [e, et, a],
      fragment(
        "(? = ?)::int * 5 + (? = ALL(?))::int * 2 + (? = ?)::int + (? = ?)::int * 2 + (?::int is null or ? = ?)::int * 2 + (?::geography is null or ST_DWithin(?::geography, ?::geography, ?::float))::int * 2 DESC",
        e.language,
        ^language,
        et.tag_id,
        ^event_tags_ids,
        e.category,
        ^category,
        e.organizer_actor_id,
        ^organizer_actor_id,
        ^group_id,
        e.attributed_to_id,
        ^group_id,
        ^geom,
        ^geom,
        a.geom,
        5000
      )
    )
    |> Repo.all()
  end

  @spec list_participations_for_user_query(integer()) :: Ecto.Query.t()
  defp list_participations_for_user_query(user_id) do
    Participant
    |> join(:inner, [p], e in Event, on: p.event_id == e.id)
    |> join(:inner, [p], a in Actor, on: p.actor_id == a.id)
    |> where([p, _e, a], a.user_id == ^user_id and p.role != ^:not_approved)
    |> preload([:event, :actor])
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

  @spec filter_public_visibility(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_public_visibility(query) do
    from(e in query, where: e.visibility == ^:public)
  end

  @spec filter_unlisted_and_public_visibility(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_unlisted_and_public_visibility(query) do
    from(q in query, where: q.visibility in ^@public_visibility)
  end

  @spec filter_not_event_uuid(Ecto.Queryable.t(), String.t() | nil) :: Ecto.Query.t()
  defp filter_not_event_uuid(query, nil), do: query

  defp filter_not_event_uuid(query, not_event_uuid) do
    from(e in query, where: e.uuid != ^not_event_uuid)
  end

  @spec filter_draft(Ecto.Queryable.t(), boolean) :: Ecto.Query.t()
  defp filter_draft(query, is_draft \\ false) do
    from(e in query, where: e.draft == ^is_draft)
  end

  @spec filter_cancelled_events(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_cancelled_events(query) do
    from(e in query, where: e.status != ^:cancelled)
  end

  @spec filter_future_events(Ecto.Queryable.t(), boolean) :: Ecto.Query.t()
  defp filter_future_events(query, true) do
    from(q in query,
      where: coalesce(q.ends_on, q.begins_on) > ^DateTime.utc_now()
    )
  end

  defp filter_future_events(query, false), do: query

  @spec filter_local(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_local(query) do
    filter_local(query, true)
  end

  @spec filter_local(Ecto.Queryable.t(), boolean() | nil) :: Ecto.Query.t()
  defp filter_local(query, nil), do: query

  defp filter_local(query, value) when is_boolean(value) do
    where(query, [q], q.local == ^value)
  end

  @spec filter_local_or_from_followed_instances_events(Ecto.Queryable.t()) ::
          Ecto.Query.t()
  defp filter_local_or_from_followed_instances_events(query) do
    %Actor{id: follower_actor_id} = Relay.get_actor()

    query
    |> join(:left, [q], s in Share, on: s.uri == q.url)
    |> join(:left, [_q, ..., s], f in Follower, on: f.target_actor_id == s.actor_id)
    |> where(
      [q, ..., s, f],
      q.local == true or (f.actor_id == ^follower_actor_id and not is_nil(s.uri))
    )
  end

  @spec filter_participant_role(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_participant_role(query) do
    filter_role(query, :participant)
  end

  @spec filter_role(Ecto.Queryable.t(), list(atom()) | atom()) :: Ecto.Query.t()
  def filter_role(query, []), do: query

  def filter_role(query, roles) when is_list(roles) do
    where(query, [p], p.role in ^roles)
  end

  def filter_role(query, role) when is_atom(role) do
    from(p in query, where: p.role == ^role)
  end

  @spec event_filter_visibility(Ecto.Queryable.t(), :public | :all) ::
          Ecto.Queryable.t() | Ecto.Query.t()
  defp event_filter_visibility(query, :all), do: query

  defp event_filter_visibility(query, :public) do
    where(query, visibility: ^:public, draft: false)
  end

  defp event_filter_begins_on(query, nil, nil), do: query

  defp event_filter_begins_on(query, %DateTime{} = after_datetime, nil) do
    where(query, [e], e.begins_on > ^after_datetime)
  end

  defp event_filter_begins_on(query, nil, %DateTime{} = before_datetime) do
    where(query, [e], e.begins_on < ^before_datetime)
  end

  defp event_filter_begins_on(
         query,
         %DateTime{} = after_datetime,
         %DateTime{} = before_datetime
       ) do
    query
    |> where([e], e.begins_on < ^before_datetime)
    |> where([e], e.begins_on > ^after_datetime)
  end

  defp event_order_by(query, order_by, direction)
       when order_by in [:begins_on, :inserted_at, :updated_at] and direction in [:asc, :desc] do
    order_by_instruction = Keyword.new([{direction, order_by}])
    order_by(query, [e], ^order_by_instruction)
  end

  defp event_order_by(query, _order_by, _direction), do: event_order_by(query, :begins_on, :asc)

  defp event_order(query, :match_desc, "") do
    query
    |> distinct([e], desc: e.begins_on, asc: e.id)
    |> order_by([e], desc: e.begins_on)
  end

  defp event_order(query, :match_desc, _) do
    query
    |> distinct([e, f], desc: f.rank, asc: e.begins_on, asc: e.id)
    |> order_by([e, f], desc: f.rank, asc: e.begins_on)
  end

  defp event_order(query, :start_time_desc, _) do
    query
    |> distinct([e], desc: e.begins_on, asc: e.id)
    |> order_by([e], desc: e.begins_on)
  end

  defp event_order(query, :start_time_asc, _) do
    query
    |> distinct([e], asc: e.begins_on, asc: e.id)
    |> order_by([e], asc: e.begins_on)
  end

  defp event_order(query, :created_at_desc, _) do
    query
    |> distinct([e], desc: e.publish_at, asc: e.id)
    |> order_by([e], desc: e.publish_at)
  end

  defp event_order(query, :created_at_asc, _) do
    query
    |> distinct([e], asc: e.publish_at, asc: e.id)
    |> order_by([e], asc: e.publish_at)
  end

  defp event_order(query, :participant_count_desc, _) do
    query
    |> distinct(:id)
    |> order_by([e], fragment("participant_stats->>'participant' DESC"))
  end

  defp event_order(query, _, _), do: query

  defp participation_filter_begins_on(query, nil, nil),
    do: participation_order_begins_on_desc(query)

  defp participation_filter_begins_on(query, %DateTime{} = after_datetime, nil) do
    query
    |> where([_p, e, _a], e.begins_on > ^after_datetime)
    |> participation_order_begins_on_asc()
  end

  defp participation_filter_begins_on(query, nil, %DateTime{} = before_datetime) do
    query
    |> where([_p, e, _a], e.begins_on < ^before_datetime)
    |> participation_order_begins_on_desc()
  end

  defp participation_filter_begins_on(
         query,
         %DateTime{} = after_datetime,
         %DateTime{} = before_datetime
       ) do
    query
    |> where([_p, e, _a], e.begins_on < ^before_datetime)
    |> where([_p, e, _a], e.begins_on > ^after_datetime)
    |> participation_order_begins_on_asc()
  end

  defp participation_order_begins_on_asc(query),
    do: order_by(query, [_p, e, _a], asc: e.begins_on)

  defp participation_order_begins_on_desc(query),
    do: order_by(query, [_p, e, _a], desc: e.begins_on)

  @spec preload_for_event(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp preload_for_event(query), do: preload(query, ^@event_preloads)

  @spec stream_events(boolean() | nil, integer()) :: Enum.t()
  def stream_events(local \\ true, chunk_size \\ 500) do
    Event
    |> filter_draft()
    |> filter_local(local)
    |> preload_for_event()
    |> Page.chunk(chunk_size)
  end
end
