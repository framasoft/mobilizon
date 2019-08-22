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
  alias Mobilizon.Service.ActivityPub.Converters.Address, as: AddressConverter
  alias Mobilizon.Service.ActivityPub.Utils
  alias Mobilizon.Events
  alias Mobilizon.Events.Tag
  alias Mobilizon.Addresses
  alias Mobilizon.Addresses.Address

  @behaviour Converter

  require Logger

  @doc """
  Converts an AP object data to our internal data structure
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map()
  def as_to_model_data(object) do
    Logger.debug("event as_to_model_data")
    Logger.debug(inspect(object))

    with {:actor, {:ok, %Actor{id: actor_id}}} <-
           {:actor, Actors.get_actor_by_url(object["actor"])},
         {:address, address_id} <-
           {:address, get_address(object["location"])},
         {:tags, tags} <- {:tags, fetch_tags(object["tag"])} do
      picture_id =
        with true <- Map.has_key?(object, "attachment") && length(object["attachment"]) > 0,
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

      {:ok,
       %{
         "title" => object["name"],
         "description" => object["content"],
         "organizer_actor_id" => actor_id,
         "picture_id" => picture_id,
         "begins_on" => object["startTime"],
         "category" => object["category"],
         "url" => object["id"],
         "uuid" => object["uuid"],
         "tags" => tags,
         "physical_address_id" => address_id
       }}
    else
      err ->
        {:error, err}
    end
  end

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

  defp do_get_address(map) do
    map = Mobilizon.Service.ActivityPub.Converters.Address.as_to_model_data(map)

    case Addresses.create_address(map) do
      {:ok, %Address{id: address_id}} ->
        address_id

      _ ->
        nil
    end
  end

  defp fetch_tags(tags) do
    Logger.debug("fetching tags")

    Enum.reduce(tags, [], fn tag, acc ->
      with true <- tag["type"] == "Hashtag",
           {:ok, %Tag{} = tag} <- Events.get_or_create_tag(tag) do
        acc ++ [tag]
      else
        _err ->
          acc
      end
    end)
  end

  defp build_tags(tags) do
    Enum.map(tags, fn %Tag{} = tag ->
      %{
        "href" => MobilizonWeb.Endpoint.url() <> "/tags/#{tag.slug}",
        "name" => "##{tag.title}",
        "type" => "Hashtag"
      }
    end)
  end

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(EventModel.t()) :: map()
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
      "publish_at" => (event.publish_at || event.inserted_at) |> date_to_string(),
      "updated_at" => event.updated_at |> date_to_string(),
      "mediaType" => "text/html",
      "startTime" => event.begins_on |> date_to_string(),
      "endTime" => event.ends_on |> date_to_string(),
      "tag" => event.tags |> build_tags(),
      "id" => event.url
    }

    res =
      if is_nil(event.physical_address),
        do: res,
        else: Map.put(res, "location", AddressConverter.model_to_as(event.physical_address))

    if is_nil(event.picture),
      do: res,
      else: Map.put(res, "attachment", [Utils.make_picture_data(event.picture)])
  end

  defp date_to_string(nil), do: nil
  defp date_to_string(date), do: DateTime.to_iso8601(date)
end

defimpl Mobilizon.Service.ActivityPub.Convertible, for: Mobilizon.Events.Event do
  alias Mobilizon.Service.ActivityPub.Converters.Event, as: EventConverter

  defdelegate model_to_as(event), to: EventConverter
end
