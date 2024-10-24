defmodule Mobilizon.GraphQL.API.Search do
  @moduledoc """
  API for search.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Service.GlobalSearch
  alias Mobilizon.Storage.Page
  import Mobilizon.GraphQL.Resolvers.Event.Utils

  require Logger

  @doc """
  Searches actors.
  """
  @spec search_actors(map(), integer | nil, integer | nil, atom()) ::
          {:ok, Page.t(Actor.t())} | {:error, String.t()}
  def search_actors(%{term: term} = args, page \\ 1, limit \\ 10, result_type) do
    term = String.trim(term)

    cond do
      # Some URLs could be domain.tld/@username, so keep this condition above
      # the `handle?` function
      url?(term) ->
        # skip, if it's not an actor
        case process_from_url(term) do
          %Page{total: _total, elements: [%Actor{} = _actor]} = page ->
            {:ok, page}

          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      handle?(term) ->
        {:ok, process_from_username(term)}

      true ->
        if global_search?(args) do
          service = GlobalSearch.service()

          {:ok, service.search_groups(Keyword.new(args, fn {k, v} -> {k, v} end))}
        else
          page =
            Actors.search_actors(
              term,
              [
                actor_type: result_type,
                radius: Map.get(args, :radius),
                location: Map.get(args, :location),
                bbox: Map.get(args, :bbox),
                minimum_visibility: Map.get(args, :minimum_visibility, :public),
                current_actor_id: Map.get(args, :current_actor_id),
                exclude_my_groups: Map.get(args, :exclude_my_groups, false),
                exclude_stale_actors: true,
                local_only: Map.get(args, :search_target, :internal) == :self,
                sort_by: Map.get(args, :sort_by)
              ],
              page,
              limit
            )

          {:ok, page}
        end
    end
  end

  @doc """
  Search events
  """
  @spec search_events(map(), integer | nil, integer | nil) ::
          {:ok, Page.t(Event.t())}
  def search_events(%{term: term} = args, page \\ 1, limit \\ 10) do
    term = String.trim(term)

    if url?(term) do
      # skip, if it's not an event
      case process_from_url(term) do
        %Page{total: _total, elements: [%Event{} = event]} = page ->
          if Map.get(args, :current_user) != nil || check_event_access?(event) do
            {:ok, page}
          else
            {:ok, %{total: 0, elements: []}}
          end

        _ ->
          {:ok, %{total: 0, elements: []}}
      end
    else
      if global_search?(args) do
        service = GlobalSearch.service()

        {:ok, service.search_events(Keyword.new(args, fn {k, v} -> {k, v} end))}
      else
        results =
          args
          |> Map.put(:term, term)
          |> Map.put(:local_only, Map.get(args, :search_target, :internal) == :self)
          |> Events.build_events_for_search(page, limit)

        {:ok, results}
      end
    end
  end

  @spec interact(String.t()) :: {:ok, struct()} | {:error, :not_found}
  def interact(uri) do
    case ActivityPub.fetch_object_from_url(uri) do
      {:ok, object} ->
        {:ok, object}

      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make object from URI '#{uri}'" end)

        {:error, :not_found}
    end
  end

  # If the search string is an username
  @spec process_from_username(String.t()) :: Page.t(Actor.t())
  defp process_from_username(search) do
    case ActivityPubActor.find_or_make_actor_from_nickname(search) do
      {:ok, %Actor{} = actor} ->
        %Page{total: 1, elements: [actor]}

      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make actor '#{search}'" end)

        %Page{total: 0, elements: []}
    end
  end

  # If the search string is an URL
  @spec process_from_url(String.t()) :: Page.t(struct())
  defp process_from_url(search) do
    case ActivityPub.fetch_object_from_url(search) do
      {:ok, object} ->
        %Page{total: 1, elements: [object]}

      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make object from URL '#{search}'" end)

        %Page{total: 0, elements: []}
    end
  end

  @spec url?(String.t()) :: boolean
  defp url?(search), do: String.starts_with?(search, ["http://", "https://"])

  @spec handle?(String.t()) :: boolean
  defp handle?(search), do: String.match?(search, ~r/@/)

  defp global_search?(%{search_target: :global}) do
    global_search_enabled?()
  end

  defp global_search?(_), do: global_search_enabled?() && global_search_default?()

  defp global_search_enabled? do
    Application.get_env(:mobilizon, :search) |> get_in([:global]) |> get_in([:is_enabled])
  end

  defp global_search_default? do
    Application.get_env(:mobilizon, :search) |> get_in([:global]) |> get_in([:is_default_search])
  end
end
