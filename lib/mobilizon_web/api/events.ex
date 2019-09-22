defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias Mobilizon.Service.ActivityPub.Activity
  alias MobilizonWeb.API.Utils

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def create_event(%{organizer_actor: organizer_actor} = args) do
    with %{
           title: title,
           physical_address: physical_address,
           picture: picture,
           content_html: content_html,
           tags: tags,
           to: to,
           cc: cc,
           begins_on: begins_on,
           ends_on: ends_on,
           category: category,
           options: options
         } <- prepare_args(args),
         event <-
           ActivityPubUtils.make_event_data(
             organizer_actor.url,
             %{to: to, cc: cc},
             title,
             content_html,
             picture,
             tags,
             %{
               begins_on: begins_on,
               ends_on: ends_on,
               physical_address: physical_address,
               category: category,
               options: options
             }
           ) do
      ActivityPub.create(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
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
         %{
           title: title,
           physical_address: physical_address,
           picture: picture,
           content_html: content_html,
           tags: tags,
           to: to,
           cc: cc,
           begins_on: begins_on,
           ends_on: ends_on,
           category: category,
           options: options
         } <-
           prepare_args(Map.merge(event, args)),
         event <-
           ActivityPubUtils.make_event_data(
             organizer_actor.url,
             %{to: to, cc: cc},
             title,
             content_html,
             picture,
             tags,
             %{
               begins_on: begins_on,
               ends_on: ends_on,
               physical_address: physical_address,
               category: category,
               options: options
             },
             event.uuid,
             event.url
           ) do
      ActivityPub.update(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: organizer_actor.url,
        cc: [],
        object: event,
        local: true
      })
    end
  end

  defp prepare_args(
         %{
           organizer_actor: organizer_actor,
           title: title,
           description: description,
           options: options,
           tags: tags,
           begins_on: begins_on,
           category: category
         } = args
       ) do
    with physical_address <- Map.get(args, :physical_address, nil),
         title <- String.trim(title),
         visibility <- Map.get(args, :visibility, :public),
         picture <- Map.get(args, :picture, nil),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(organizer_actor, description, visibility, tags, nil) do
      %{
        title: title,
        physical_address: physical_address,
        picture: picture,
        content_html: content_html,
        tags: tags,
        to: to,
        cc: cc,
        begins_on: begins_on,
        ends_on: Map.get(args, :ends_on, nil),
        category: category,
        options: options
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
