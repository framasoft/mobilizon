defmodule MobilizonWeb.API.Search do
  @moduledoc """
  API for search.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.ActorType
  alias Mobilizon.Events
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Storage.Page

  require Logger

  @doc """
  Searches actors.
  """
  @spec search_actors(String.t(), integer | nil, integer | nil, ActorType.t()) ::
          {:ok, Page.t()} | {:error, String.t()}
  def search_actors(search, page \\ 1, limit \\ 10, result_type) do
    search = String.trim(search)

    cond do
      search == "" ->
        {:error, "Search can't be empty"}

      # Some URLs could be domain.tld/@username, so keep this condition above
      # the `is_handle` function
      is_url(search) ->
        # skip, if it's not an actor
        case process_from_url(search) do
          %Page{total: _total, elements: _elements} = page ->
            {:ok, page}

          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      is_handle(search) ->
        {:ok, process_from_username(search)}

      true ->
        page = Actors.build_actors_by_username_or_name_page(search, [result_type], page, limit)

        {:ok, page}
    end
  end

  @doc """
  Search events
  """
  @spec search_events(String.t(), integer | nil, integer | nil) ::
          {:ok, Page.t()} | {:error, String.t()}
  def search_events(search, page \\ 1, limit \\ 10) do
    search = String.trim(search)

    cond do
      search == "" ->
        {:error, "Search can't be empty"}

      is_url(search) ->
        # skip, if it's w not an actor
        case process_from_url(search) do
          %Page{total: _total, elements: _elements} = page ->
            {:ok, page}

          _ ->
            {:ok, %{total: 0, elements: []}}
        end

      true ->
        {:ok, Events.build_events_by_name(search, page, limit)}
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
