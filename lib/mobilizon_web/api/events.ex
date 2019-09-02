defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias MobilizonWeb.API.Utils

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def create_event(%{organizer_actor: organizer_actor} = args) do
    with %{
           title: title,
           physical_address: physical_address,
           visibility: visibility,
           picture: picture,
           content_html: content_html,
           tags: tags,
           to: to,
           cc: cc,
           begins_on: begins_on,
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
             %{begins_on: begins_on, physical_address: physical_address, category: category, options: options}
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
  @spec update_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def update_event(
        %{
          organizer_actor: organizer_actor,
          event: event
        } = args
      ) do
    with %{
           title: title,
           physical_address: physical_address,
           visibility: visibility,
           picture: picture,
           content_html: content_html,
           tags: tags,
           to: to,
           cc: cc,
           begins_on: begins_on,
           category: category,
           options: options
         } <-
           prepare_args(
             args
             |> update_args(event)
           ),
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
               physical_address: physical_address,
               category: Map.get(args, :category),
               options: options
             }
           ) do
      ActivityPub.update(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: organizer_actor,
        object: event,
        local: true
      })
    end
  end

  defp update_args(args, event) do
    %{
      title: Map.get(args, :title, event.title),
      description: Map.get(args, :description, event.description),
      tags: Map.get(args, :tags, event.tags),
      physical_address: Map.get(args, :physical_address, event.physical_address),
      visibility: Map.get(args, :visibility, event.visibility),
      physical_address: Map.get(args, :physical_address, event.physical_address),
      begins_on: Map.get(args, :begins_on, event.begins_on),
      category: Map.get(args, :category, event.category),
      options: Map.get(args, :options, event.options)
    }
  end

  defp prepare_args(
         %{
           organizer_actor: organizer_actor,
           title: title,
           description: description,
           options: options,
           tags: tags,
           begins_on: begins_on,
           category: category,
           options: options
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
        visibility: visibility,
        picture: picture,
        content_html: content_html,
        tags: tags,
        to: to,
        cc: cc,
        begins_on: begins_on,
        category: category,
        options: options
      }
    end
  end
end
