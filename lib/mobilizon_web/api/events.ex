defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias Mobilizon.Service.ActivityPub.Activity
  alias MobilizonWeb.API.Utils

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def create_event(%{organizer_actor: organizer_actor} = args) do
    with args <- prepare_args(args),
         event <-
           ActivityPubUtils.make_event_data(
             args.organizer_actor.url,
             %{to: args.to, cc: args.cc},
             args.title,
             args.content_html,
             args.picture,
             args.tags,
             args.metadata
           ) do
      ActivityPub.create(%{
        to: args.to,
        actor: organizer_actor,
        object: event,
        local: true
      })
    end
  end

  @doc """
  Update an event
  """
  @spec update_event(map(), Event.t()) :: {:ok, Activity.t(), Event.t()} | any()
  def update_event(
        %{
          organizer_actor: organizer_actor
        } = args,
        %Event{} = event
      ) do
    with args <- Map.put(args, :tags, Map.get(args, :tags, [])),
         args <- prepare_args(Map.merge(event, args)),
         event <-
           ActivityPubUtils.make_event_data(
             args.organizer_actor.url,
             %{to: args.to, cc: args.cc},
             args.title,
             args.content_html,
             args.picture,
             args.tags,
             args.metadata,
             event.uuid,
             event.url
           ) do
      ActivityPub.update(%{
        to: args.to,
        actor: organizer_actor.url,
        cc: [],
        object: event,
        local: true
      })
    end
  end

  defp prepare_args(args) do
    with %Actor{} = organizer_actor <- Map.get(args, :organizer_actor),
         title <- args |> Map.get(:title, "") |> String.trim(),
         visibility <- Map.get(args, :visibility, :public),
         description <- Map.get(args, :description),
         tags <- Map.get(args, :tags),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(organizer_actor, description, visibility, tags, nil) do
      %{
        title: title,
        content_html: content_html,
        picture: Map.get(args, :picture),
        tags: tags,
        organizer_actor: organizer_actor,
        to: to,
        cc: cc,
        metadata: %{
          begins_on: Map.get(args, :begins_on),
          ends_on: Map.get(args, :ends_on),
          physical_address: Map.get(args, :physical_address),
          category: Map.get(args, :category),
          options: Map.get(args, :options),
          join_options: Map.get(args, :join_options),
          status: Map.get(args, :status),
          online_address: Map.get(args, :online_address),
          phone_address: Map.get(args, :phone_address)
        }
      }
    end
  end

  @doc """
  Trigger the deletion of an event

  If the event is deleted by
  """
  def delete_event(%Event{} = event, federate \\ true) do
    ActivityPub.delete(event, federate)
  end
end
