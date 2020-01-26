defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def create_event(args) do
    with organizer_actor <- Map.get(args, :organizer_actor),
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
  @spec update_event(map(), Event.t()) :: {:ok, Activity.t(), Event.t()} | any()
  def update_event(args, %Event{} = event) do
    with organizer_actor <- Map.get(args, :organizer_actor),
         args <-
           Map.update(args, :picture, nil, fn picture ->
             process_picture(picture, organizer_actor)
           end) do
      ActivityPub.update(:event, event, args, Map.get(args, :draft, false) == false)
    end
  end

  @doc """
  Trigger the deletion of an event

  If the event is deleted by
  """
  def delete_event(%Event{} = event, federate \\ true) do
    ActivityPub.delete(event, federate)
  end

  defp process_picture(nil, _), do: nil
  defp process_picture(%{picture_id: _picture_id} = args, _), do: args

  defp process_picture(%{picture: picture}, %Actor{id: actor_id}) do
    %{
      file:
        picture
        |> Map.get(:file)
        |> Utils.make_picture_data(description: Map.get(picture, :name)),
      actor_id: actor_id
    }
  end
end
