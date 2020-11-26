defmodule Mobilizon.GraphQL.API.Events do
  @moduledoc """
  API for Events.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils

  @doc """
  Create an event
  """
  @spec create_event(map) :: {:ok, Activity.t(), Event.t()} | any
  def create_event(args) do
    with organizer_actor <- Map.get(args, :organizer_actor),
         args <- extract_pictures_from_event_body(args, organizer_actor),
         args <-
           Map.update(args, :picture, nil, fn picture ->
             process_picture(picture, organizer_actor)
           end) do
      # For now we don't federate drafts but it will be needed if we want to edit them as groups
      ActivityPub.create(:event, args, args.draft == false)
    end
  end

  @doc """
  Update an event
  """
  @spec update_event(map, Event.t()) :: {:ok, Activity.t(), Event.t()} | any
  def update_event(args, %Event{} = event) do
    with organizer_actor <- Map.get(args, :organizer_actor),
         args <- extract_pictures_from_event_body(args, organizer_actor),
         args <-
           Map.update(args, :picture, nil, fn picture ->
             process_picture(picture, organizer_actor)
           end) do
      ActivityPub.update(event, args, Map.get(args, :draft, false) == false)
    end
  end

  @doc """
  Trigger the deletion of an event
  """
  def delete_event(%Event{} = event, %Actor{} = actor, federate \\ true) do
    ActivityPub.delete(event, actor, federate)
  end

  defp process_picture(nil, _), do: nil
  defp process_picture(%{media_id: _picture_id} = args, _), do: args

  defp process_picture(%{media: media}, %Actor{id: actor_id}) do
    %{
      file:
        media
        |> Map.get(:file)
        |> Utils.make_media_data(description: Map.get(media, :name)),
      actor_id: actor_id
    }
  end

  @spec extract_pictures_from_event_body(map(), Actor.t()) :: map()
  defp extract_pictures_from_event_body(
         %{description: description} = args,
         %Actor{id: organizer_actor_id}
       ) do
    pictures = APIUtils.extract_pictures_from_body(description, organizer_actor_id)
    Map.put(args, :media, pictures)
  end

  defp extract_pictures_from_event_body(args, _), do: args
end
