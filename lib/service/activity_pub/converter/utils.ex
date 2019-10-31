defmodule Mobilizon.Service.ActivityPub.Converter.Utils do
  @moduledoc """
  Various utils for converters
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Tag
  alias Mobilizon.Mention
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Storage.Repo
  require Logger

  @spec fetch_tags([String.t()]) :: [Tag.t()]
  def fetch_tags(tags) when is_list(tags) do
    Logger.debug("fetching tags")

    Enum.reduce(tags, [], &fetch_tag/2)
  end

  @spec fetch_mentions([map()]) :: [map()]
  def fetch_mentions(mentions) when is_list(mentions) do
    Logger.debug("fetching mentions")

    Enum.reduce(mentions, [], fn mention, acc -> create_mention(mention, acc) end)
  end

  def fetch_address(%{id: id}) do
    with {id, ""} <- Integer.parse(id) do
      %{id: id}
    end
  end

  def fetch_address(address) when is_map(address) do
    address
  end

  @spec build_tags([Tag.t()]) :: [Map.t()]
  def build_tags(tags) do
    Enum.map(tags, fn %Tag{} = tag ->
      %{
        "href" => MobilizonWeb.Endpoint.url() <> "/tags/#{tag.slug}",
        "name" => "##{tag.title}",
        "type" => "Hashtag"
      }
    end)
  end

  def build_mentions(mentions) do
    Enum.map(mentions, fn %Mention{} = mention ->
      if Ecto.assoc_loaded?(mention.actor) do
        build_mention(mention.actor)
      else
        build_mention(Repo.preload(mention, [:actor]).actor)
      end
    end)
  end

  defp build_mention(%Actor{} = actor) do
    %{
      "href" => actor.url,
      "name" => "@#{Mobilizon.Actors.Actor.preferred_username_and_domain(actor)}",
      "type" => "Mention"
    }
  end

  defp fetch_tag(tag, acc) when is_map(tag) do
    case tag["type"] do
      "Hashtag" ->
        acc ++ [%{title: tag}]

      _err ->
        acc
    end
  end

  defp fetch_tag(tag, acc) when is_bitstring(tag) do
    acc ++ [%{title: tag}]
  end

  @spec create_mention(map(), list()) :: list()
  defp create_mention(%Actor{id: actor_id} = _mention, acc) do
    acc ++ [%{actor_id: actor_id}]
  end

  @spec create_mention(map(), list()) :: list()
  defp create_mention(mention, acc) when is_map(mention) do
    with true <- mention["type"] == "Mention",
         {:ok, %Actor{id: actor_id}} <- ActivityPub.get_or_fetch_actor_by_url(mention["href"]) do
      acc ++ [%{actor_id: actor_id}]
    else
      _err ->
        acc
    end
  end

  @spec create_mention({String.t(), map()}, list()) :: list()
  defp create_mention({_, mention}, acc) when is_map(mention) do
    create_mention(mention, acc)
  end
end
