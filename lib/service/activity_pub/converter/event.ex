defmodule Mobilizon.Service.ActivityPub.Converter.Event do
  @moduledoc """
  Event converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Addresses
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event, as: EventModel
  alias Mobilizon.Media.Picture
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.{Converter, Convertible}
  alias Mobilizon.Service.ActivityPub.Converter.Address, as: AddressConverter
  alias Mobilizon.Service.ActivityPub.Converter.Picture, as: PictureConverter
  alias Mobilizon.Service.ActivityPub.Converter.Utils, as: ConverterUtils

  require Logger

  @behaviour Converter

  defimpl Convertible, for: EventModel do
    alias Mobilizon.Service.ActivityPub.Converter.Event, as: EventConverter

    defdelegate model_to_as(event), to: EventConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map()} | {:error, any()}
  def as_to_model_data(object) do
    Logger.debug("event as_to_model_data")
    Logger.debug(inspect(object))

    with author_url <- Map.get(object, "actor") || Map.get(object, "attributedTo"),
         {:actor, {:ok, %Actor{id: actor_id, domain: actor_domain}}} <-
           {:actor, ActivityPub.get_or_fetch_actor_by_url(author_url)},
         {:address, address_id} <-
           {:address, get_address(object["location"])},
         {:tags, tags} <- {:tags, ConverterUtils.fetch_tags(object["tag"])},
         {:mentions, mentions} <- {:mentions, ConverterUtils.fetch_mentions(object["tag"])},
         {:visibility, visibility} <- {:visibility, get_visibility(object)},
         {:options, options} <- {:options, get_options(object)} do
      picture_id =
        with true <- Map.has_key?(object, "attachment") && length(object["attachment"]) > 0,
             {:ok, %Picture{id: picture_id}} <-
               object["attachment"]
               |> hd
               |> PictureConverter.find_or_create_picture(actor_id) do
          picture_id
        else
          _err ->
            nil
        end

      entity = %{
        title: object["name"],
        description: object["content"],
        organizer_actor_id: actor_id,
        picture_id: picture_id,
        begins_on: object["startTime"],
        ends_on: object["endTime"],
        category: object["category"],
        visibility: visibility,
        join_options: Map.get(object, "joinMode", "free"),
        local: is_nil(actor_domain),
        options: options,
        status: object |> Map.get("ical:status", "CONFIRMED") |> String.downcase(),
        online_address: object["onlineAddress"],
        phone_address: object["phoneAddress"],
        draft: false,
        url: object["id"],
        uuid: object["uuid"],
        tags: tags,
        mentions: mentions,
        physical_address_id: address_id,
        updated_at: object["updated"],
        publish_at: object["published"]
      }

      {:ok, entity}
    else
      error ->
        {:error, error}
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(EventModel.t()) :: map
  def model_to_as(%EventModel{} = event) do
    to =
      if event.visibility == :public,
        do: ["https://www.w3.org/ns/activitystreams#Public"],
        else: [event.organizer_actor.followers_url]

    res = %{
      "type" => "Event",
      "to" => to,
      "cc" => [],
      "attributedTo" => event.organizer_actor.url,
      "name" => event.title,
      "actor" => event.organizer_actor.url,
      "uuid" => event.uuid,
      "category" => event.category,
      "content" => event.description,
      "published" => (event.publish_at || event.inserted_at) |> date_to_string(),
      "updated" => event.updated_at |> date_to_string(),
      "mediaType" => "text/html",
      "startTime" => event.begins_on |> date_to_string(),
      "joinMode" => to_string(event.join_options),
      "endTime" => event.ends_on |> date_to_string(),
      "tag" => event.tags |> ConverterUtils.build_tags(),
      "maximumAttendeeCapacity" => event.options.maximum_attendee_capacity,
      "repliesModerationOption" => event.options.comment_moderation,
      "commentsEnabled" => event.options.comment_moderation == :allow_all,
      # "draft" => event.draft,
      "ical:status" => event.status |> to_string |> String.upcase(),
      "id" => event.url,
      "url" => event.url
    }

    res =
      if is_nil(event.physical_address),
        do: res,
        else: Map.put(res, "location", AddressConverter.model_to_as(event.physical_address))

    if is_nil(event.picture),
      do: res,
      else: Map.put(res, "attachment", [PictureConverter.model_to_as(event.picture)])
  end

  # Get only elements that we have in EventOptions
  @spec get_options(map) :: map
  defp get_options(object) do
    %{
      maximum_attendee_capacity: object["maximumAttendeeCapacity"],
      comment_moderation:
        Map.get(
          object,
          "repliesModerationOption",
          if(Map.get(object, "commentsEnabled", true), do: :allow_all, else: :closed)
        )
    }
  end

  @spec get_address(map | binary | nil) :: integer | nil
  defp get_address(address_url) when is_bitstring(address_url) do
    get_address(%{"id" => address_url})
  end

  defp get_address(%{"id" => url} = map) when is_map(map) and is_binary(url) do
    Logger.debug("Address with an URL, let's check against our own database")

    case Addresses.get_address_by_url(url) do
      %Address{id: address_id} ->
        address_id

      _ ->
        Logger.debug("not in our database, let's try to create it")
        map = Map.put(map, "url", map["id"])
        do_get_address(map)
    end
  end

  defp get_address(map) when is_map(map) do
    do_get_address(map)
  end

  defp get_address(nil), do: nil

  @spec do_get_address(map) :: integer | nil
  defp do_get_address(map) do
    map = Mobilizon.Service.ActivityPub.Converter.Address.as_to_model_data(map)

    case Addresses.create_address(map) do
      {:ok, %Address{id: address_id}} ->
        address_id

      _ ->
        nil
    end
  end

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  defp get_visibility(object), do: if(@ap_public in object["to"], do: :public, else: :unlisted)

  @spec date_to_string(DateTime.t() | nil) :: String.t()
  defp date_to_string(nil), do: nil
  defp date_to_string(%DateTime{} = date), do: DateTime.to_iso8601(date)
end
