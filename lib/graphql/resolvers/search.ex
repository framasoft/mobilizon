defmodule Mobilizon.GraphQL.Resolvers.Search do
  @moduledoc """
  Handles the event-related GraphQL calls
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.GraphQL.API.Search
  alias Mobilizon.Storage.Page

  @doc """
  Search persons
  """
  @spec search_persons(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Actor.t())} | {:error, String.t()}
  def search_persons(_parent, %{page: page, limit: limit} = args, _resolution) do
    Search.search_actors(Map.put(args, :minimum_visibility, :private), page, limit, :Person)
  end

  @doc """
  Search groups
  """
  @spec search_groups(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Actor.t())} | {:error, String.t()}
  def search_groups(
        _parent,
        %{page: page, limit: limit} = args,
        %{context: context} = _resolution
      ) do
    current_actor = Map.get(context, :current_actor)
    current_actor_id = if current_actor, do: current_actor.id, else: nil
    args = Map.put(args, :current_actor_id, current_actor_id)
    Search.search_actors(args, page, limit, :Group)
  end

  @doc """
  Search events
  """
  @spec search_events(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Event.t())} | {:error, String.t()}
  def search_events(
        _parent,
        %{page: page, limit: limit} = args,
        %{context: context} = _resolution
      ) do
    current_user = Map.get(context, :current_user)
    args = Map.put(args, :current_user, current_user)
    Search.search_events(args, page, limit)
  end

  @spec interact(any(), map(), Absinthe.Resolution.t()) :: {:ok, struct} | {:error, :not_found}
  def interact(_parent, %{uri: uri}, _resolution) do
    Search.interact(uri)
  end
end
