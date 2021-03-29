defmodule Mobilizon.GraphQL.Resolvers.FeedToken do
  @moduledoc """
  Handles the feed tokens-related GraphQL calls.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Create an feed token for an user and optionally a defined actor
  """
  @spec create_feed_token(any, map, map) :: {:ok, FeedToken.t()} | {:error, String.t()}
  def create_feed_token(
        _parent,
        %{actor_id: actor_id},
        %{context: %{current_user: %User{id: id} = user}}
      ) do
    with {:is_owned, %Actor{}} <- User.owns_actor(user, actor_id),
         {:ok, feed_token} <- Events.create_feed_token(%{user_id: id, actor_id: actor_id}) do
      {:ok, to_short_uuid(feed_token)}
    else
      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  @spec create_feed_token(any, map, map) :: {:ok, FeedToken.t()}
  def create_feed_token(_parent, %{}, %{context: %{current_user: %User{id: id}}}) do
    with {:ok, feed_token} <- Events.create_feed_token(%{user_id: id}) do
      {:ok, to_short_uuid(feed_token)}
    end
  end

  @spec create_feed_token(any, map, map) :: {:error, String.t()}
  def create_feed_token(_parent, _args, %{}) do
    {:error, dgettext("errors", "You are not allowed to create a feed token if not connected")}
  end

  @doc """
  Delete a feed token
  """
  @spec delete_feed_token(any, map, map) :: {:ok, map} | {:error, String.t()}
  def delete_feed_token(
        _parent,
        %{token: token},
        %{context: %{current_user: %User{id: id} = _user}}
      ) do
    with {:ok, token} <- ShortUUID.decode(token),
         {:ok, token} <- Ecto.UUID.cast(token),
         {:no_token, %FeedToken{actor: actor, user: %User{} = user} = feed_token} <-
           {:no_token, Events.get_feed_token(token)},
         {:token_from_user, true} <- {:token_from_user, id == user.id},
         {:ok, _} <- Events.delete_feed_token(feed_token) do
      res = %{user: %{id: id}}
      res = if is_nil(actor), do: res, else: Map.put(res, :actor, %{id: actor.id})
      {:ok, res}
    else
      {:error, nil} ->
        {:error, dgettext("errors", "No such feed token")}

      :error ->
        {:error, dgettext("errors", "Token is not a valid UUID")}

      {:error, "Invalid input"} ->
        {:error, dgettext("errors", "Token is not a valid UUID")}

      {:no_token, _} ->
        {:error, dgettext("errors", "Token does not exist")}

      {:token_from_user, false} ->
        {:error, dgettext("errors", "You don't have permission to delete this token")}
    end
  end

  @spec delete_feed_token(any, map, map) :: {:error, String.t()}
  def delete_feed_token(_parent, _args, %{}) do
    {:error, dgettext("errors", "You are not allowed to delete a feed token if not connected")}
  end

  defp to_short_uuid(%FeedToken{token: token} = feed_token) do
    %FeedToken{feed_token | token: ShortUUID.encode!(token)}
  end
end
