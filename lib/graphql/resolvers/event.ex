defmodule Mobilizon.GraphQL.Resolvers.Event do
  @moduledoc """
  Handles the event-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Admin, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.{Event, EventParticipantStats}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.API

  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Federation.ActivityPub.Permission
  alias Mobilizon.Service.AntiSpam
  alias Mobilizon.Service.TimezoneDetector
  import Mobilizon.Users.Guards, only: [is_moderator: 1]
  import Mobilizon.Web.Gettext
  import Mobilizon.GraphQL.Resolvers.Event.Utils
  require Logger

  # We limit the max number of events that can be retrieved
  @event_max_limit 100
  @number_of_related_events 4

  @spec organizer_for_event(Event.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t() | nil} | {:error, String.t()}
  def organizer_for_event(
        %Event{attributed_to_id: attributed_to_id, organizer_actor_id: organizer_actor_id},
        _args,
        %{
          context: %{current_user: %User{role: user_role}, current_actor: %Actor{id: actor_id}}
        } = _resolution
      )
      when not is_nil(attributed_to_id) do
    with %Actor{id: group_id} <- Actors.get_actor(attributed_to_id),
         {:member, true} <-
           {:member, Actors.member?(actor_id, group_id) or is_moderator(user_role)},
         %Actor{} = actor <- Actors.get_actor(organizer_actor_id) do
      {:ok, actor}
    else
      _ -> {:ok, nil}
    end
  end

  def organizer_for_event(
        %Event{attributed_to_id: attributed_to_id},
        _args,
        _resolution
      )
      when not is_nil(attributed_to_id) do
    case Actors.get_actor(attributed_to_id) do
      %Actor{} -> {:ok, nil}
      _ -> {:error, "Unable to get organizer actor"}
    end
  end

  def organizer_for_event(
        %Event{organizer_actor_id: organizer_actor_id},
        _args,
        _resolution
      ) do
    case Actors.get_actor(organizer_actor_id) do
      %Actor{} = actor -> {:ok, actor}
      _ -> {:error, "Unable to get organizer actor"}
    end
  end

  @spec list_events(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Event.t())} | {:error, :events_max_limit_reached}
  def list_events(
        _parent,
        %{
          page: page,
          limit: limit,
          order_by: order_by,
          direction: direction,
          long_events: long_events,
          location: location,
          radius: radius
        },
        _resolution
      )
      when limit < @event_max_limit do
    {:ok,
     Events.list_events(page, limit, order_by, direction, true, long_events, location, radius)}
  end

  def list_events(
        _parent,
        %{page: page, limit: limit, order_by: order_by, direction: direction},
        _resolution
      )
      when limit < @event_max_limit do
    {:ok, Events.list_events(page, limit, order_by, direction, true)}
  end

  def list_events(_parent, %{page: _page, limit: _limit}, _resolution) do
    {:error, :events_max_limit_reached}
  end

  @spec find_private_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Event.t()} | {:error, :event_not_found}
  defp find_private_event(
         _parent,
         %{uuid: uuid},
         %{context: %{current_actor: %Actor{} = profile}} = _resolution
       ) do
    case Events.get_event_by_uuid_with_preload(uuid) do
      # Event attributed to group
      %Event{attributed_to: %Actor{}} = event ->
        if Permission.can_access_group_object?(profile, event) do
          {:ok, event}
        else
          {:error, :event_not_found}
        end

      # Own event
      %Event{organizer_actor: %Actor{id: actor_id}} = event ->
        if actor_id == profile.id do
          {:ok, event}
        else
          {:error, :event_not_found}
        end

      _ ->
        {:error, :event_not_found}
    end
  end

  defp find_private_event(_parent, _args, _resolution) do
    {:error, :event_not_found}
  end

  @spec find_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Event.t()} | {:error, :event_not_found}
  def find_event(parent, %{uuid: uuid} = args, %{context: context} = resolution) do
    case Events.get_public_event_by_uuid_with_preload(uuid) do
      %Event{} = event ->
        if Map.has_key?(context, :current_user) || check_event_access?(event) do
          {:ok, event}
        else
          {:error, :event_not_found}
        end

      _ ->
        find_private_event(parent, args, resolution)
    end
  end

  @doc """
  List participants for event (through an event request)
  """
  @spec list_participants_for_event(Event.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Participant.t())} | {:error, String.t()}
  def list_participants_for_event(
        %Event{id: event_id} = event,
        %{page: page, limit: limit, roles: roles},
        %{context: %{current_actor: %Actor{} = actor}} = _resolution
      ) do
    # Check that moderator has right
    if can_event_be_updated_by?(event, actor) do
      roles =
        case roles do
          nil ->
            []

          "" ->
            []

          roles ->
            roles
            |> String.split(",")
            |> Enum.map(&String.downcase/1)
            |> Enum.map(&String.to_existing_atom/1)
        end

      participants = Events.list_participants_for_event(event_id, roles, page, limit)
      {:ok, participants}
    else
      {:error,
       dgettext("errors", "Provided profile doesn't have moderator permissions on this event")}
    end
  end

  def list_participants_for_event(_, _args, _resolution) do
    {:ok, %{total: 0, elements: []}}
  end

  @spec stats_participants(Event.t(), map(), Absinthe.Resolution.t()) :: {:ok, map()}
  def stats_participants(
        %Event{participant_stats: %EventParticipantStats{} = stats, id: event_id} = _event,
        _args,
        %{context: %{current_user: %User{id: user_id} = _user}} = _resolution
      ) do
    if Events.user_moderator_for_event?(user_id, event_id) do
      {:ok,
       Map.put(
         stats,
         :going,
         stats.participant + stats.moderator + stats.administrator + stats.creator
       )}
    else
      {:ok, %EventParticipantStats{participant: stats.participant}}
    end
  end

  def stats_participants(
        %Event{participant_stats: %EventParticipantStats{participant: participant}},
        _args,
        _resolution
      ) do
    {:ok, %EventParticipantStats{participant: participant}}
  end

  def stats_participants(_event, _args, _resolution) do
    {:ok, %EventParticipantStats{}}
  end

  @doc """
  List related events
  """
  @spec list_related_events(Event.t(), map(), Absinthe.Resolution.t()) :: {:ok, list(Event.t())}
  def list_related_events(
        %Event{uuid: uuid} = event,
        _args,
        _resolution
      ) do
    # We get the organizer's next public event
    events =
      event
      |> Events.related_events()
      # We've considered all recommended events, so we fetch the latest events
      |> add_latest_events()
      # We remove the same event from the results
      |> Enum.filter(fn event -> event.uuid != uuid end)
      # We return only @number_of_related_events right now
      |> Enum.take(@number_of_related_events)

    {:ok, events}
  end

  @spec add_latest_events(list(Event.t())) :: list(Event.t())
  defp add_latest_events(events) do
    if @number_of_related_events - length(events) > 0 do
      events
      |> Enum.concat(
        Events.list_events(1, @number_of_related_events + 1, :begins_on, :asc, true).elements
      )
      |> uniq_events()
    else
      events
    end
  end

  @spec uniq_events(list(Event.t())) :: list(Event.t())
  defp uniq_events(events), do: Enum.uniq_by(events, fn event -> event.uuid end)

  @doc """
  Create an event
  """
  @spec create_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Event.t()} | {:error, String.t() | Ecto.Changeset.t()}
  def create_event(
        _parent,
        %{organizer_actor_id: organizer_actor_id} = args,
        %{context: %{current_user: %User{email: email} = user} = context} = _resolution
      ) do
    current_ip = Map.get(context, :ip)
    user_agent = Map.get(context, :user_agent, "")

    with {:is_owned, %Actor{} = organizer_actor} <- User.owns_actor(user, organizer_actor_id),
         {:can_create_event, true} <- can_create_event(args),
         {:event_external, true} <- edit_event_external_checker(args),
         {:organizer_group_member, true} <-
           {:organizer_group_member, organizer_group_member?(args)},
         args_with_organizer <-
           args |> Map.put(:organizer_actor, organizer_actor) |> extract_timezone(user.id),
         {:askismet, :ham} <-
           {:askismet,
            AntiSpam.service().check_event(
              args.description,
              organizer_actor.preferred_username,
              email,
              current_ip,
              user_agent
            )},
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.create_event(args_with_organizer) do
      {:ok, event}
    else
      {:is_owned, nil} ->
        {:error, dgettext("errors", "Organizer profile is not owned by the user")}

      {:can_create_event, false} ->
        {:error,
         dgettext(
           "errors",
           "Only groups can create events"
         )}

      {:event_external, false} ->
        {:error,
         dgettext(
           "errors",
           "Providing external registration is not allowed"
         )}

      {:organizer_group_member, false} ->
        {:error,
         dgettext(
           "errors",
           "Organizer profile doesn't have permission to create an event on behalf of this group"
         )}

      {:askismet, _} ->
        {:error,
         dgettext(
           "errors",
           "This event was detected as spam."
         )}

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}

      {:error, err} ->
        Logger.warning("Unknown error while creating event: #{inspect(err)}")

        {:error,
         dgettext(
           "errors",
           "Unknown error while creating event"
         )}
    end
  end

  def create_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to create events")}
  end

  @spec can_create_event(map()) :: {:can_create_event, boolean()}
  defp can_create_event(args) do
    if Config.only_groups_can_create_events?() do
      {:can_create_event, Map.get(args, :attributed_to_id) != nil}
    else
      {:can_create_event, true}
    end
  end

  @spec edit_event_external_checker(map()) :: {:event_external, boolean()}
  defp edit_event_external_checker(args) do
    if Config.instance_event_external_enabled?() do
      {:event_external, true}
    else
      {:event_external,
       Map.get(args, :join_options) != :external and
         is_nil(Map.get(args, :external_participation_url))}
    end
  end

  @doc """
  Update an event
  """
  @spec update_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Event.t()} | {:error, String.t() | Ecto.Changeset.t()}
  def update_event(
        _parent,
        %{event_id: event_id} = args,
        %{context: %{current_user: %User{} = user, current_actor: %Actor{} = actor}} = _resolution
      ) do
    # See https://github.com/absinthe-graphql/absinthe/issues/490
    args = Map.put(args, :options, args[:options] || %{})

    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:ok, args} <- verify_profile_change(args, event, user, actor),
         args <- extract_timezone(args, user.id),
         {:event_can_be_managed, true} <-
           {:event_can_be_managed, can_event_be_updated_by?(event, actor)},
         {:event_external, true} <- edit_event_external_checker(args),
         {:ok, %Activity{data: %{"object" => %{"type" => "Event"}}}, %Event{} = event} <-
           API.Events.update_event(args, event) do
      {:ok, event}
    else
      {:event_can_be_managed, false} ->
        {:error,
         dgettext(
           "errors",
           "This profile doesn't have permission to update an event on behalf of this group"
         )}

      {:event_external, false} ->
        {:error,
         dgettext(
           "errors",
           "Providing external registration is not allowed"
         )}

      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event not found")}

      {:old_actor, _} ->
        {:error, dgettext("errors", "You can't edit this event.")}

      {:new_actor, _} ->
        {:error, dgettext("errors", "You can't attribute this event to this profile.")}

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}
    end
  end

  def update_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to update an event")}
  end

  @doc """
  Delete an event
  """
  @spec delete_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Event.t()} | {:error, String.t() | Ecto.Changeset.t()}
  def delete_event(
        _parent,
        %{event_id: event_id},
        %{
          context: %{
            current_user: %User{role: role},
            current_actor: %Actor{id: actor_id} = actor
          }
        }
      ) do
    case Events.get_event_with_preload(event_id) do
      {:ok, %Event{local: is_local} = event} ->
        cond do
          {:event_can_be_managed, true} ==
              {:event_can_be_managed, can_event_be_deleted_by?(event, actor)} ->
            do_delete_event(event, actor)

          role in [:moderator, :administrator] ->
            with {:ok, res} <- do_delete_event(event, actor, !is_local),
                 %Actor{} = actor <- Actors.get_actor(actor_id) do
              Admin.log_action(actor, "delete", event)

              {:ok, res}
            end

          true ->
            {:error, dgettext("errors", "You cannot delete this event")}
        end

      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event not found")}
    end
  end

  def delete_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to delete an event")}
  end

  @spec do_delete_event(Event.t(), Actor.t(), boolean()) :: {:ok, map()}
  defp do_delete_event(%Event{} = event, %Actor{} = actor, federate \\ true)
       when is_boolean(federate) do
    with {:ok, _activity, event} <- API.Events.delete_event(event, actor) do
      {:ok, %{id: event.id}}
    end
  end

  @spec organizer_group_member?(map()) :: boolean()
  defp organizer_group_member?(%{
         attributed_to_id: attributed_to_id,
         organizer_actor_id: organizer_actor_id
       })
       when not is_nil(attributed_to_id) do
    Actors.member?(organizer_actor_id, attributed_to_id) &&
      Permission.can_create_group_object?(organizer_actor_id, attributed_to_id, %Event{})
  end

  defp organizer_group_member?(_), do: true

  @spec verify_profile_change(map(), Event.t(), User.t(), Actor.t()) :: {:ok, map()}
  defp verify_profile_change(
         args,
         %Event{attributed_to: %Actor{}},
         %User{} = _user,
         %Actor{} = current_profile
       ) do
    # The organizer_actor has to be the current profile, because otherwise we're left with a possible remote organizer
    args =
      args
      |> Map.put(:organizer_actor, current_profile)
      |> Map.put(:organizer_actor_id, current_profile.id)

    {:ok, args}
  end

  defp verify_profile_change(
         args,
         %Event{organizer_actor: %Actor{id: organizer_actor_id}},
         %User{} = user,
         %Actor{} = _actor
       ) do
    with {:old_actor, {:is_owned, %Actor{}}} <-
           {:old_actor, User.owns_actor(user, organizer_actor_id)},
         new_organizer_actor_id <- args |> Map.get(:organizer_actor_id, organizer_actor_id),
         {:new_actor, {:is_owned, %Actor{} = organizer_actor}} <-
           {:new_actor, User.owns_actor(user, new_organizer_actor_id)},
         args <-
           args
           |> Map.put(:organizer_actor, organizer_actor)
           |> Map.put(:organizer_actor_id, organizer_actor.id) do
      {:ok, args}
    end
  end

  @spec extract_timezone(map(), String.t() | integer()) :: map()
  defp extract_timezone(args, user_id) do
    event_options = Map.get(args, :options, %{})
    timezone = Map.get(event_options, :timezone)
    physical_address = Map.get(args, :physical_address)

    fallback_tz =
      case Mobilizon.Users.get_setting(user_id) do
        nil -> nil
        setting -> setting |> Map.from_struct() |> get_in([:timezone])
      end

    timezone = determine_timezone(timezone, physical_address, fallback_tz)

    event_options = Map.put(event_options, :timezone, timezone)

    Map.put(args, :options, event_options)
  end

  @spec determine_timezone(
          String.t() | nil,
          any(),
          String.t() | nil
        ) :: String.t() | nil
  defp determine_timezone(timezone, physical_address, fallback_tz) do
    case physical_address do
      physical_address when is_map(physical_address) ->
        TimezoneDetector.detect(
          timezone,
          Map.get(physical_address, :geom),
          fallback_tz
        )

      _ ->
        timezone || fallback_tz
    end
  end
end
