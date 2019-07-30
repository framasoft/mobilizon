defmodule MobilizonWeb.API.Events do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Addresses
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias MobilizonWeb.API.Utils

  @doc """
  Create an event
  """
  @spec create_event(map()) :: {:ok, Activity.t(), Event.t()} | any()
  def create_event(
        %{
          title: title,
          description: description,
          organizer_actor_id: organizer_actor_id,
          begins_on: begins_on,
          category: category,
          tags: tags
        } = args
      ) do
    with %Actor{url: url} = actor <-
           Actors.get_local_actor_with_everything(organizer_actor_id),
         physical_address <- Map.get(args, :physical_address, nil),
         title <- String.trim(title),
         visibility <- Map.get(args, :visibility, :public),
         picture <- Map.get(args, :picture, nil),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(actor, description, visibility, tags, nil),
         event <-
           ActivityPubUtils.make_event_data(
             url,
             %{to: to, cc: cc},
             title,
             content_html,
             picture,
             tags,
             %{begins_on: begins_on, physical_address: physical_address, category: category}
           ) do
      ActivityPub.create(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: actor,
        object: event,
        local: true
      })
    end
  end

  defp get_physical_address(address_id) when is_number(address_id),
    do: Addresses.get_address!(address_id)

  defp get_physical_address(address_id) when is_binary(address_id) do
    with {address_id, ""} <- Integer.parse(address_id) do
      get_physical_address(address_id)
    end
  end

  defp get_physical_address(nil), do: nil
end
