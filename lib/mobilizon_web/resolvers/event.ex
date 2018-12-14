defmodule MobilizonWeb.Resolvers.Event do
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Actors

  def list_events(_parent, %{page: page, limit: limit}, _resolution) do
    {:ok, Mobilizon.Events.list_events(page, limit)}
  end

  def find_event(_parent, %{uuid: uuid}, _resolution) do
    case Mobilizon.Events.get_event_full_by_uuid(uuid) do
      nil ->
        {:error, "Event with UUID #{uuid} not found"}

      event ->
        {:ok, event}
    end
  end

  @doc """
  List participant for event (separate request)
  """
  def list_participants_for_event(_parent, %{uuid: uuid}, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid)}
  end

  @doc """
  List participants for event (through an event request)
  """
  def list_participants_for_event(%{uuid: uuid}, %{page: page, limit: limit}, _resolution) do
    {:ok, Mobilizon.Events.list_participants_for_event(uuid, page, limit)}
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
    search = String.trim(search)

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

  def create_event(_parent, args, %{context: %{current_user: user}}) do
    organizer_actor_id = Map.get(args, :organizer_actor_id) || Actors.get_actor_for_user(user).id
    args = args |> Map.put(:organizer_actor_id, organizer_actor_id)
    Mobilizon.Events.create_event(args)
  end

  def create_event(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create events"}
  end
end
