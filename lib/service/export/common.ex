defmodule Mobilizon.Service.Export.Common do
  @moduledoc """
  Common tools for exportation
  """

  alias Mobilizon.{Actors, Events, Posts, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @spec fetch_actor_event_feed(String.t(), integer()) ::
          {:ok, Actor.t(), [Event.t()], [Post.t()]}
          | {:error, :actor_not_public | :actor_not_found}
  def fetch_actor_event_feed(name, limit) do
    case Actors.get_actor_by_name(name) do
      %Actor{} = actor ->
        if Actor.is_public_visibility?(actor) do
          %Page{elements: events} = Events.list_public_events_for_actor(actor, 1, limit)
          %Page{elements: posts} = Posts.get_public_posts_for_group(actor, 1, limit)
          {:ok, actor, events, posts}
        else
          {:error, :actor_not_public}
        end

      nil ->
        {:error, :actor_not_found}
    end
  end

  @typep token_feed_data :: %{
           type: :actor | :user,
           actor: Actor.t() | nil,
           user: User.t(),
           events: [Event.t()],
           token: String.t()
         }

  # Only events, not posts
  @spec fetch_events_from_token(String.t(), integer()) ::
          token_feed_data | {:error, :bad_token | :token_not_found}
  def fetch_events_from_token(token, limit) do
    case uuid_from_token(token) do
      {:ok, uuid} ->
        case Events.get_feed_token(uuid) do
          nil ->
            {:error, :token_not_found}

          %FeedToken{actor: actor, user: %User{} = user} ->
            produce_actor_feed(actor, user, token, limit)
        end

      {:error, :bad_token} ->
        {:error, :bad_token}
    end
  end

  @spec uuid_from_token(String.t()) :: {:ok, String.t()} | {:error, :bad_token}
  defp uuid_from_token(token) do
    case ShortUUID.decode(token) do
      {:ok, uuid} ->
        case Ecto.UUID.cast(uuid) do
          {:ok, _uuid} ->
            {:ok, uuid}

          :error ->
            {:error, :bad_token}
        end

      {:error, _err} ->
        {:error, :bad_token}
    end
  end

  @spec produce_actor_feed(Actor.t() | nil, User.t(), String.t(), integer()) :: token_feed_data
  defp produce_actor_feed(%Actor{} = actor, %User{} = user, token, limit) do
    %{
      type: :actor,
      actor: actor,
      events: fetch_actor_private_events(actor, limit),
      user: user,
      token: token
    }
  end

  defp produce_actor_feed(nil, %User{} = user, token, limit) do
    with actors <- Users.get_actors_for_user(user),
         events <-
           actors
           |> Enum.map(&fetch_actor_private_events(&1, limit))
           |> Enum.concat() do
      %{type: :user, events: events, user: user, token: token, actor: nil}
    end
  end

  @spec fetch_instance_public_content(integer()) :: {:ok, list(Event.t()), list(Post.t())}
  def fetch_instance_public_content(limit) do
    %Page{elements: events} = Events.list_public_local_events(1, limit)
    %Page{elements: posts} = Posts.list_public_local_posts(1, limit)
    {:ok, events, posts}
  end

  @spec fetch_actor_private_events(Actor.t(), integer()) :: list(Event.t())
  defp fetch_actor_private_events(%Actor{} = actor, limit) do
    actor |> fetch_identity_participations(limit) |> participations_to_events()
  end

  @spec fetch_identity_participations(Actor.t(), integer()) :: Page.t()
  defp fetch_identity_participations(%Actor{} = actor, limit) do
    with %Page{} = page <- Events.list_event_participations_for_actor(actor, 1, limit) do
      page
    end
  end

  defp participations_to_events(%Page{elements: participations}) do
    participations
    |> Enum.map(& &1.event_id)
    |> Enum.map(&Events.get_event_with_preload!/1)
  end
end
