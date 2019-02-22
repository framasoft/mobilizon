defmodule MobilizonWeb.API.Search do
  @moduledoc """
  API for Search
  """
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Comment}

  require Logger

  @doc """
  Search
  """
  @spec search(String.t(), integer(), integer()) ::
          {:ok, list(Actor.t())} | {:ok, []} | {:error, any()}
  def search(search, page \\ 1, limit \\ 10) do
    do_search(search, page, limit, %{events: true, actors: true})
  end

  @doc """
  Not used at the moment
  """
  # TODO: Use me
  @spec search_actors(String.t(), integer(), integer()) ::
          {:ok, list(Actor.t())} | {:ok, []} | {:error, any()}
  def search_actors(search, page \\ 1, limit \\ 10) do
    do_search(search, page, limit, %{actors: true})
  end

  @doc """
  Not used at the moment
  """
  # TODO: Use me
  @spec search_events(String.t(), integer(), integer()) ::
          {:ok, list(Event.t())} | {:ok, []} | {:error, any()}
  def search_events(search, page \\ 1, limit \\ 10) do
    do_search(search, page, limit, %{events: true})
  end

  # Do the actual search
  @spec do_search(String.t(), integer(), integer(), map()) :: {:ok, list(any())}
  defp do_search(search, page, limit, opts) do
    search = String.trim(search)

    cond do
      search == "" ->
        {:error, "Search can't be empty"}

      String.match?(search, ~r/@/) ->
        {:ok, process_from_username(search)}

      String.starts_with?(search, "https://") ->
        {:ok, process_from_url(search)}

      String.starts_with?(search, "http://") ->
        {:ok, process_from_url(search)}

      true ->
        events =
          Task.async(fn ->
            if Map.get(opts, :events, false),
              do: Events.find_events_by_name(search, page, limit),
              else: []
          end)

        actors =
          Task.async(fn ->
            if Map.get(opts, :actors, false),
              do: Actors.find_actors_by_username_or_name(search, page, limit),
              else: []
          end)

        {:ok, Task.await(events) ++ Task.await(actors)}
    end
  end

  # If the search string is an username
  @spec process_from_username(String.t()) :: Actor.t() | nil
  defp process_from_username(search) do
    with {:ok, actor} <- ActivityPub.find_or_make_actor_from_nickname(search) do
      actor
    else
      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make actor '#{search}'" end)
        nil
    end
  end

  # If the search string is an URL
  @spec process_from_url(String.t()) :: Actor.t() | Event.t() | Comment.t() | nil
  defp process_from_url(search) do
    with {:ok, object} <- ActivityPub.fetch_object_from_url(search) do
      object
    else
      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make object from URL '#{search}'" end)
        nil
    end
  end
end
