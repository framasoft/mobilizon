defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Formatter
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  import MobilizonWeb.API.Utils

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t()} | any()
  def create_event(
        %{
          title: title,
          description: description,
          organizer_actor_id: organizer_actor_id,
          begins_on: begins_on,
          category: category
        } = args
      ) do
    with %Actor{url: url} = actor <-
           Actors.get_local_actor_with_everything(organizer_actor_id),
         title <- String.trim(title),
         mentions <- Formatter.parse_mentions(description),
         visibility <- Map.get(args, :visibility, "public"),
         {to, cc} <- to_for_actor_and_mentions(actor, mentions, nil, Atom.to_string(visibility)),
         tags <- Formatter.parse_tags(description),
         picture <- Map.get(args, :picture, nil),
         content_html <-
           make_content_html(
             description,
             mentions,
             tags,
             "text/plain"
           ),
         event <-
           ActivityPubUtils.make_event_data(
             url,
             to,
             title,
             content_html,
             picture,
             tags,
             cc,
             %{begins_on: begins_on},
             category
           ) do
      ActivityPub.create(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: actor,
        object: event,
        local: true
      })
    end
  end
end
