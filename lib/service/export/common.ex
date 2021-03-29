defmodule Mobilizon.Service.Export.Common do
  @moduledoc """
  Common tools for exportation
  """

  alias Mobilizon.{Actors, Events, Posts, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @spec fetch_actor_event_feed(String.t()) :: String.t()
  def fetch_actor_event_feed(name) do
    with %Actor{} = actor <- Actors.get_actor_by_name(name),
         {:visibility, true} <- {:visibility, Actor.is_public_visibility?(actor)},
         %Page{elements: events} <- Events.list_public_events_for_actor(actor),
         %Page{elements: posts} <- Posts.get_public_posts_for_group(actor) do
      {:ok, actor, events, posts}
    else
      err ->
        {:error, err}
    end
  end

  # Only events, not posts
  @spec fetch_events_from_token(String.t()) :: String.t()
  def fetch_events_from_token(token) do
    with {:ok, uuid} <- ShortUUID.decode(token),
         {:ok, _uuid} <- Ecto.UUID.cast(uuid),
         %FeedToken{actor: actor, user: %User{} = user} <- Events.get_feed_token(uuid) do
      case actor do
        %Actor{} = actor ->
          %{
            type: :actor,
            actor: actor,
            events: fetch_actor_private_events(actor),
            user: user,
            token: token
          }

        nil ->
          with actors <- Users.get_actors_for_user(user),
               events <-
                 actors
                 |> Enum.map(&fetch_actor_private_events/1)
                 |> Enum.concat() do
            %{type: :user, events: events, user: user, token: token, actor: nil}
          end
      end
    end
  end

  @spec fetch_instance_public_content :: {:ok, list(Event.t()), list(Post.t())}
  def fetch_instance_public_content do
    with %Page{elements: events} <- Events.list_public_local_events(),
         %Page{elements: posts} <- Posts.list_public_local_posts() do
      {:ok, events, posts}
    end
  end

  @spec fetch_actor_private_events(Actor.t()) :: list(Event.t())
  def fetch_actor_private_events(%Actor{} = actor) do
    actor |> fetch_identity_participations() |> participations_to_events()
  end

  @spec fetch_identity_participations(Actor.t()) :: Page.t()
  defp fetch_identity_participations(%Actor{} = actor) do
    with %Page{} = page <- Events.list_event_participations_for_actor(actor) do
      page
    end
  end

  defp participations_to_events(%Page{elements: participations}) do
    participations
    |> Enum.map(& &1.event_id)
    |> Enum.map(&Events.get_event_with_preload!/1)
  end
end
