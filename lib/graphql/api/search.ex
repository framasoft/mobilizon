defmodule Mobilizon.GraphQL.API.Search do
  @moduledoc """
  API for search.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, ActorType}
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Page

  alias Mobilizon.Federation.ActivityPub

  require Logger

  @doc """
  Searches actors.
  """
  @spec search_actors(map(), integer | nil, integer | nil, ActorType.t()) ::
          {:ok, Page.t()} | {:error, String.t()}
  def search_actors(%{term: term} = args, page \\ 1, limit \\ 10, result_type) do
    term = String.trim(term)

    cond do
      # Some URLs could be domain.tld/@username, so keep this condition above
      # the `is_handle` function
      is_url(term) ->
        # skip, if it's not an actor
        case process_from_url(term) do
          %Page{total: _total, elements: [%Actor{} = _actor]} = page ->
            {:ok, page}

          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      is_handle(term) ->
        {:ok, process_from_username(term)}

      true ->
        page =
          Actors.build_actors_by_username_or_name_page(
            term,
            [
              actor_type: [result_type],
              radius: Map.get(args, :radius),
              location: Map.get(args, :location),
              minimum_visibility: :public
            ],
            page,
            limit
          )

        {:ok, page}
    end
  end

  @doc """
  Search events
  """
  @spec search_events(String.t(), integer | nil, integer | nil) ::
          {:ok, Page.t()} | {:error, String.t()}
  def search_events(%{term: term} = args, page \\ 1, limit \\ 10) do
    term = String.trim(term)

    if is_url(term) do
      # skip, if it's w not an actor
      case process_from_url(term) do
        %Page{total: _total, elements: [%Event{} = _event]} = page ->
          {:ok, page}

        _ ->
          {:ok, %{total: 0, elements: []}}
      end
    else
      {:ok, Events.build_events_for_search(Map.put(args, :term, term), page, limit)}
    end
  end

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
  @spec process_from_username(String.t()) :: Page.t()
  defp process_from_username(search) do
    case ActivityPub.find_or_make_actor_from_nickname(search) do
      {:ok, actor} ->
        %Page{total: 1, elements: [actor]}

      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make actor '#{search}'" end)

        %Page{total: 0, elements: []}
    end
  end

  # If the search string is an URL
  @spec process_from_url(String.t()) :: Page.t()
  defp process_from_url(search) do
    case ActivityPub.fetch_object_from_url(search) do
      {:ok, object} ->
        %Page{total: 1, elements: [object]}

      {:error, _err} ->
        Logger.debug(fn -> "Unable to find or make object from URL '#{search}'" end)

        %Page{total: 0, elements: []}
    end
  end

  @spec is_url(String.t()) :: boolean
  defp is_url(search), do: String.starts_with?(search, ["http://", "https://"])

  @spec is_handle(String.t()) :: boolean
  defp is_handle(search), do: String.match?(search, ~r/@/)
end
