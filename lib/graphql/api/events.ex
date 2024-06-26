defmodule Mobilizon.GraphQL.API.Events do
  @moduledoc """
  API for Events.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity, Utils}
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils

  @doc """
  Create an event
  """
  @spec create_event(map) ::
          {:ok, Activity.t(), Event.t()} | {:error, atom() | Ecto.Changeset.t()}
  def create_event(args) do
    # For now we don't federate drafts but it will be needed if we want to edit them as groups
    Actions.Create.create(:event, prepare_args(args), should_federate(args))
  end

  @doc """
  Update an event
  """
  @spec update_event(map, Event.t()) ::
          {:ok, Activity.t(), Event.t()} | {:error, atom | Ecto.Changeset.t()}
  def update_event(args, %Event{} = event) do
    Actions.Update.update(event, prepare_args(args), should_federate(args))
  end

  @doc """
  Trigger the deletion of an event
  """
  @spec delete_event(Event.t(), Actor.t()) :: {:ok, Activity.t(), Entity.t()} | any()
  def delete_event(%Event{} = event, %Actor{} = actor) do
    Actions.Delete.delete(event, actor, true)
  end

  @spec send_private_message_to_participants(map()) ::
          {:ok, Activity.t(), Comment.t()} | {:error, atom() | Ecto.Changeset.t()}
  def send_private_message_to_participants(args) do
    Actions.Create.create(:comment, args, true)
  end

  @spec prepare_args(map) :: map
  defp prepare_args(args) do
    organizer_actor = Map.get(args, :organizer_actor)

    args
    |> extract_pictures_from_event_body(organizer_actor)
    |> Map.update(:picture, nil, fn picture ->
      process_picture(picture, organizer_actor)
    end)
  end

  defp process_picture(nil, _), do: nil
  defp process_picture(%{media_id: _picture_id} = args, _), do: args

  defp process_picture(%{media: media}, %Actor{id: actor_id}) do
    # case url
    if Map.has_key?(media, :url) do
      %{
        file: %{"url" => media.url, "name" => media.name},
        actor_id: actor_id
      }

      # case upload
    else
      with uploaded when is_map(uploaded) <-
             media
             |> Map.get(:file)
             |> Utils.make_media_data(description: Map.get(media, :name)) do
        %{
          file: Map.take(uploaded, [:url, :name, :content_type, :size]),
          metadata: Map.take(uploaded, [:width, :height, :blurhash]),
          actor_id: actor_id
        }
      end
    end
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

  @spec should_federate(map()) :: boolean
  defp should_federate(%{attributed_to_id: attributed_to_id}) when not is_nil(attributed_to_id),
    do: true

  defp should_federate(args), do: Map.get(args, :draft, false) == false
end
