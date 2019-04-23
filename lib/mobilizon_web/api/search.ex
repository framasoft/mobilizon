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
  Search actors
  """
  @spec search_actors(String.t(), integer(), integer(), String.t()) ::
          {:ok, %{total: integer(), elements: list(Actor.t())}} | {:error, any()}
  def search_actors(search, page \\ 1, limit \\ 10, result_type) do
    search = String.trim(search)

    cond do
      search == "" ->
        {:error, "Search can't be empty"}

      # Some URLs could be domain.tld/@username, so keep this condition above handle_search? function
      url_search?(search) ->
        # If this is not an actor, skip
        with %{:total => total, :elements => [%Actor{}] = elements} <- process_from_url(search) do
          {:ok, %{total: total, elements: elements}}
        else
          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      handle_search?(search) ->
        {:ok, process_from_username(search)}

      true ->
        {:ok,
         Actors.find_and_count_actors_by_username_or_name(search, [result_type], page, limit)}
    end
  end

  @doc """
  Search events
  """
  @spec search_events(String.t(), integer(), integer()) ::
          {:ok, %{total: integer(), elements: list(Event.t())}} | {:error, any()}
  def search_events(search, page \\ 1, limit \\ 10) do
    search = String.trim(search)

    cond do
      search == "" ->
        {:error, "Search can't be empty"}

      url_search?(search) ->
        # If this is not an event, skip
        with {total = total, [%Event{} = elements]} <- process_from_url(search) do
          {:ok, %{total: total, elements: elements}}
        else
          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      true ->
        {:ok, Events.find_and_count_events_by_name(search, page, limit)}
    end
  end

  # If the search string is an username
  @spec process_from_username(String.t()) :: %{total: integer(), elements: [Actor.t()]}
  defp process_from_username(search) do
    with {:ok, actor} <- ActivityPub.find_or_make_actor_from_nickname(search) do
      %{total: 1, elements: [actor]}
    else
      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make actor '#{search}'" end)
        %{total: 0, elements: []}
    end
  end

  # If the search string is an URL
  @spec process_from_url(String.t()) :: %{
          total: integer(),
          elements: [Actor.t() | Event.t() | Comment.t()]
        }
  defp process_from_url(search) do
    with {:ok, object} <- ActivityPub.fetch_object_from_url(search) do
      %{total: 1, elements: [object]}
    else
      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make object from URL '#{search}'" end)
        %{total: 0, elements: []}
    end
  end

  # Is the search an URL search?
  @spec url_search?(String.t()) :: boolean
  defp url_search?(search) do
    String.starts_with?(search, "https://") or String.starts_with?(search, "http://")
  end

  # Is the search an handle search?
  @spec handle_search?(String.t()) :: boolean
  defp handle_search?(search) do
    String.match?(search, ~r/@/)
  end
end
