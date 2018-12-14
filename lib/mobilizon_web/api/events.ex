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

  @spec create_event(map()) :: {:ok, Activity.t()} | any()
  def create_event(
        %{
          title: title,
          description: description,
          organizer_actor_username: organizer_actor_username,
          begins_on: begins_on,
          category: category
        } = args
      ) do
    with %Actor{url: url} = actor <- Actors.get_local_actor_by_name(organizer_actor_username),
         title <- String.trim(title),
         mentions <- Formatter.parse_mentions(description),
         visibility <- Map.get(args, :visibility, "public"),
         {to, cc} <- to_for_actor_and_mentions(actor, mentions, nil, visibility),
         tags <- Formatter.parse_tags(description),
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
