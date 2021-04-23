defmodule Mobilizon.Federation.ActivityStream.Converter.Resource do
  @moduledoc """
  Resource converter.

  This module allows to convert resources from ActivityStream format to our own
  internal one, and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Resources
  alias Mobilizon.Resources.Resource
  require Logger

  @behaviour Converter

  defimpl Convertible, for: Resource do
    alias Mobilizon.Federation.ActivityStream.Converter.Resource, as: ResourceConverter

    defdelegate model_to_as(resource), to: ResourceConverter
  end

  @doc """
  Convert an resource struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(Resource.t()) :: map
  def model_to_as(
        %Resource{actor: %Actor{url: actor_url}, creator: %Actor{url: creator_url}, type: type} =
          resource
      ) do
    res = %{
      "actor" => creator_url,
      "id" => resource.url,
      "name" => resource.title,
      "summary" => resource.summary,
      "context" => get_context(resource),
      "attributedTo" => actor_url,
      "published" => resource.published_at |> DateTime.to_iso8601()
    }

    case type do
      :folder ->
        Map.put(res, "type", "ResourceCollection")

      _ ->
        res
        |> Map.put("type", "Document")
        |> Map.put("url", resource.resource_url)
    end
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(%{"type" => type, "actor" => creator, "attributedTo" => group} = object) do
    with {:ok, %Actor{id: actor_id, resources_url: resources_url}} <- get_actor(group),
         {:ok, %Actor{id: creator_id}} <- get_actor(creator),
         parent_id <- get_parent_id(object["context"], resources_url) do
      data = %{
        title: object["name"],
        summary: object["summary"],
        url: object["id"],
        actor_id: actor_id,
        creator_id: creator_id,
        parent_id: parent_id,
        published_at: object["published"]
      }

      case type do
        "Document" ->
          data
          |> Map.put(:type, :link)
          |> Map.put(:resource_url, object["url"])

        "ResourceCollection" ->
          data
          |> Map.put(:type, :folder)
      end
    else
      {:error, err} -> {:error, err}
      err -> {:error, err}
    end
  end

  @spec get_actor(String.t() | map() | nil) :: {:ok, Actor.t()} | {:error, String.t()}
  defp get_actor(nil), do: {:error, "nil property found for actor data"}

  defp get_actor(actor),
    do: actor |> Utils.get_url() |> ActivityPubActor.get_or_fetch_actor_by_url()

  defp get_context(%Resource{parent_id: nil, actor: %Actor{resources_url: resources_url}}),
    do: resources_url

  defp get_context(%Resource{parent: %Resource{url: url}}), do: url

  defp get_context(%Resource{parent_id: parent_id}),
    do: parent_id |> Resources.get_resource() |> Map.get(:url)

  @spec get_parent_id(String.t(), String.t()) :: Resource.t() | map()
  defp get_parent_id(context, resources_url) do
    Logger.debug(
      "Getting parentID for context #{inspect(context)} and with resources_url #{
        inspect(resources_url)
      }"
    )

    case Utils.get_url(context) do
      nil -> nil
      ^resources_url -> nil
      context_url -> fetch_resource(context_url)
    end
  end

  defp fetch_resource(context_url) do
    case Resources.get_resource_by_url(context_url) do
      %Resource{id: resource_id} = _resource ->
        resource_id

      nil ->
        case ActivityPub.fetch_object_from_url(context_url) do
          {:ok, %Resource{id: resource_id} = _resource} ->
            resource_id

          _ ->
            nil
        end
    end
  end
end
