defmodule Mobilizon.GraphQL.Resolvers.Participant do
  @moduledoc """
  Handles the participation-related GraphQL calls.
  """
  alias Mobilizon.{Actors, Config, Crypto, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.GraphQL.API.Participations
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.Email.Checker
  require Logger
  import Mobilizon.Web.Gettext

  @doc """
  Join an event for an regular or anonymous actor
  """
  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id} = args,
        %{context: %{current_user: %User{} = user}}
      ) do
    case User.owns_actor(user, actor_id) do
      {:is_owned, %Actor{} = actor} ->
        do_actor_join_event(actor, event_id, args)

      _ ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id} = args,
        _resolution
      ) do
    with {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_with_preload(event_id)},
         {:anonymous_participation_enabled, true} <-
           {:anonymous_participation_enabled,
            event.local == true && Config.anonymous_participation?() &&
              event.options.anonymous_participation == true},
         {:anonymous_actor_id, true} <-
           {:anonymous_actor_id, to_string(Config.anonymous_actor_id()) == actor_id},
         {:email_required, true} <-
           {:email_required,
            Config.anonymous_participation_email_required?() &&
              args |> Map.get(:email) |> valid_email?()},
         {:confirmation_token, {confirmation_token, role}} <-
           {:confirmation_token,
            if(Config.anonymous_participation_email_confirmation_required?(),
              do: {Crypto.random_string(30), :not_confirmed},
              else: {nil, :participant}
            )},
         # We only federate if the participation is not to be confirmed later
         args <-
           args
           |> Map.put(:confirmation_token, confirmation_token)
           |> Map.put(:cancellation_token, Crypto.random_string(30))
           |> Map.put(:role, role)
           |> Map.put(:local, role == :participant),
         {:actor_not_found, %Actor{} = actor} <-
           {:actor_not_found, Actors.get_actor_with_preload(actor_id)},
         {:ok, %Participant{} = participant} <- do_actor_join_event(actor, event_id, args) do
      if Config.anonymous_participation_email_required?() &&
           Config.anonymous_participation_email_confirmation_required?() do
        args
        |> Map.get(:email)
        |> Email.Participation.anonymous_participation_confirmation(
          participant,
          Map.get(args, :locale, "en")
        )
        |> Email.Mailer.send_email_later()
      end

      {:ok, participant}
    else
      {:error, err} ->
        {:error, err}

      {:has_event, _} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}

      {:anonymous_participation_enabled, false} ->
        {:error, dgettext("errors", "Anonymous participation is not enabled")}

      {:anonymous_actor_id, false} ->
        {:error, dgettext("errors", "Profile ID provided is not the anonymous profile one")}

      {:email_required, _} ->
        {:error, dgettext("errors", "A valid email is required by your instance")}

      {:actor_not_found, _} ->
        Logger.error(
          "The actor ID \"#{actor_id}\" provided by configuration doesn't match any actor in database"
        )

        {:error, dgettext("errors", "Internal Error")}
    end
  end

  def actor_join_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to join an event")}
  end

  @spec do_actor_join_event(Actor.t(), integer | String.t(), map()) ::
          {:ok, Participant.t()} | {:error, String.t()}
  defp do_actor_join_event(actor, event_id, args) do
    with {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Events.get_event_with_preload(event_id)},
         {:ok, _activity, participant} <- Participations.join(event, actor, args),
         %Participant{} = participant <-
           participant
           |> Map.put(:event, event)
           |> Map.put(:actor, actor) do
      {:ok, participant}
    else
      {:maximum_attendee_capacity, _} ->
        {:error, dgettext("errors", "The event has already reached its maximum capacity")}

      {:has_event, _} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}

      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event id not found")}

      {:ok, %Participant{}} ->
        {:error, dgettext("errors", "You are already a participant of this event")}
    end
  end

  @doc """
  Leave an event for an anonymous actor
  """
  def actor_leave_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id, token: token},
        _resolution
      )
      when not is_nil(token) do
    with {:anonymous_participation_enabled, true} <-
           {:anonymous_participation_enabled, Config.anonymous_participation?()},
         {:anonymous_actor_id, true} <-
           {:anonymous_actor_id, to_string(Config.anonymous_actor_id()) == actor_id},
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_with_preload(event_id)},
         %Actor{} = actor <- Actors.get_actor_with_preload(actor_id),
         {:ok, _activity, %Participant{id: participant_id} = _participant} <-
           Participations.leave(event, actor, %{local: false, cancellation_token: token}) do
      {:ok, %{event: %{id: event_id}, actor: %{id: actor_id}, id: participant_id}}
    else
      {:has_event, _} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}

      {:only_organizer, true} ->
        {:error,
         dgettext(
           "errors",
           "You can't leave event because you're the only event creator participant"
         )}

      {:error, :participant_not_found} ->
        {:error, dgettext("errors", "Participant not found")}
    end
  end

  def actor_leave_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id},
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Events.get_event_with_preload(event_id)},
         {:ok, _activity, _participant} <- Participations.leave(event, actor) do
      {:ok, %{event: %{id: event_id}, actor: %{id: actor_id}}}
    else
      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}

      {:only_organizer, true} ->
        {:error,
         dgettext(
           "errors",
           "You can't leave event because you're the only event creator participant"
         )}

      {:error, :participant_not_found} ->
        {:error, dgettext("errors", "Participant not found")}
    end
  end

  def actor_leave_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to leave an event")}
  end

  def update_participation(
        _parent,
        %{id: participation_id, role: new_role},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    # Check that moderator provided is rightly authenticated
    with %Actor{id: moderator_actor_id} = moderator_actor <- Users.get_actor_for_user(user),
         # Check that participation already exists
         {:has_participation, %Participant{role: old_role} = participation} <-
           {:has_participation, Events.get_participant(participation_id)},
         {:same_role, false} <- {:same_role, new_role == old_role},
         # Check that moderator has right
         {:actor_approve_permission, true} <-
           {:actor_approve_permission,
            Events.moderator_for_event?(participation.event.id, moderator_actor_id)},
         {:ok, _activity, participation} <-
           Participations.update(participation, moderator_actor, new_role) do
      {:ok, participation}
    else
      {:has_participation, nil} ->
        {:error, dgettext("errors", "Participant not found")}

      {:actor_approve_permission, _} ->
        {:error,
         dgettext("errors", "Provided profile doesn't have moderator permissions on this event")}

      {:same_role, true} ->
        {:error, dgettext("errors", "Participant already has role %{role}", role: new_role)}

      {:error, :participant_not_found} ->
        {:error, dgettext("errors", "Participant not found")}
    end
  end

  @spec confirm_participation_from_token(map(), map(), map()) ::
          {:ok, Participant.t()} | {:error, String.t()}
  def confirm_participation_from_token(
        _parent,
        %{confirmation_token: confirmation_token},
        _context
      ) do
    with {:has_participant,
          %Participant{actor: actor, role: :not_confirmed, event: event} = participant} <-
           {:has_participant, Events.get_participant_by_confirmation_token(confirmation_token)},
         default_role <- Events.get_default_participant_role(event),
         {:ok, _activity, %Participant{} = participant} <-
           Participations.update(participant, actor, default_role) do
      {:ok, participant}
    else
      {:has_participant, _} ->
        {:error, dgettext("errors", "This token is invalid")}
    end
  end

  @spec valid_email?(String.t() | nil) :: boolean
  defp valid_email?(email) when is_nil(email), do: false

  defp valid_email?(email) when is_binary(email) do
    email
    |> String.trim()
    |> Checker.valid?()
  end
end
