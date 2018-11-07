defmodule MobilizonWeb.Resolvers.Event do
  alias Mobilizon.Service.ActivityPub

  def list_events(_parent, _args, _resolution) do
    {:ok, Mobilizon.Events.list_events()}
  end

  def find_event(_parent, %{uuid: uuid}, _resolution) do
    case Mobilizon.Events.get_event_full_by_uuid(uuid) do
      nil ->
        {:error, "Event with UUID #{uuid} not found"}

      event ->
        {:ok, event}
    end
  end

  def list_participants_for_event(_parent, %{uuid: uuid}, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid)}
  end

  @doc """
  Search events by title
  """
  def search_events(_parent, %{search: search, page: page, limit: limit}, _resolution) do
    {:ok, Mobilizon.Events.find_events_by_name(search, page, limit)}
  end

  @doc """
  Search events and actors by title
  """
  def search_events_and_actors(_parent, %{search: search, page: page, limit: limit}, _resolution) do
    search = String.strip(search)

    found =
      case String.contains?(search, "@") do
        true ->
          with {:ok, actor} <- ActivityPub.find_or_make_actor_from_nickname(search) do
            actor
          else
            {:error, _err} ->
              nil
          end

        _ ->
          Mobilizon.Events.find_events_by_name(search, page, limit) ++
            Mobilizon.Actors.find_actors_by_username_or_name(search, page, limit)
      end

    require Logger
    Logger.debug(inspect(found))
    {:ok, found}
  end

  @doc """
  List participants for event (through an event request)
  """
  def list_participants_for_event(%{uuid: uuid}, _args, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid)}
  end

  def create_event(_parent, args, %{context: %{current_user: user}}) do
    Mobilizon.Events.create_event(args)
  end

  def create_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create events"}
  end
end
