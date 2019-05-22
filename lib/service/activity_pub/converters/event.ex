defmodule Mobilizon.Service.ActivityPub.Converters.Event do
  @moduledoc """
  Event converter

  This module allows to convert events from ActivityStream format to our own internal one, and back
  """
  alias Mobilizon.Actors
  alias Mobilizon.Media
  alias Mobilizon.Media.Picture
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event, as: EventModel
  alias Mobilizon.Service.ActivityPub.Converter

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map()
  def as_to_model_data(object) do
    with {:ok, %Actor{id: actor_id}} <- Actors.get_actor_by_url(object["actor"]) do
      picture_id =
        with true <- Map.has_key?(object, "attachment"),
             %Picture{id: picture_id} <-
               Media.get_picture_by_url(
                 object["attachment"]
                 |> hd
                 |> Map.get("url")
                 |> hd
                 |> Map.get("href")
               ) do
          picture_id
        else
          _ -> nil
        end

      %{
        "title" => object["name"],
        "description" => object["content"],
        "organizer_actor_id" => actor_id,
        "picture_id" => picture_id,
        "begins_on" => object["begins_on"],
        "category" => object["category"],
        "url" => object["id"],
        "uuid" => object["uuid"]
      }
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(EventModel.t()) :: map()
  def model_to_as(%EventModel{} = event) do
    %{
      "type" => "Event",
      "to" => ["https://www.w3.org/ns/activitystreams#Public"],
      "title" => event.title,
      "actor" => event.organizer_actor.url,
      "uuid" => event.uuid,
      "category" => event.category,
      "summary" => event.description,
      "publish_at" => (event.publish_at || event.inserted_at) |> DateTime.to_iso8601(),
      "updated_at" => event.updated_at |> DateTime.to_iso8601(),
      "id" => event.url
    }
  end
end
