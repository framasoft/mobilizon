defmodule Mobilizon.Federation.ActivityStream.Converter.Utils do
  @moduledoc """
  Various utils for converters.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Tag
  alias Mobilizon.Mention
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Federation.ActivityPub

  require Logger

  @spec fetch_tags([String.t()]) :: [Tag.t()]
  def fetch_tags(tags) when is_list(tags) do
    Logger.debug("fetching tags")
    Logger.debug(inspect(tags))

    tags |> Enum.flat_map(&fetch_tag/1) |> Enum.uniq() |> Enum.map(&existing_tag_or_data/1)
  end

  @spec fetch_mentions([map()]) :: [map()]
  def fetch_mentions(mentions) when is_list(mentions) do
    Logger.debug("fetching mentions")

    Enum.reduce(mentions, [], fn mention, acc -> create_mention(mention, acc) end)
  end

  def fetch_address(%{id: id}) do
    with {id, ""} <- Integer.parse(id), do: %{id: id}
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

  defp fetch_tag(%{title: title}), do: [title]

  defp fetch_tag(tag) when is_map(tag) do
    case tag["type"] do
      "Hashtag" ->
        [tag_without_hash(tag["name"])]

      _err ->
        []
    end
  end

  defp fetch_tag(tag) when is_bitstring(tag), do: [tag_without_hash(tag)]

  defp tag_without_hash("#" <> tag_title), do: tag_title
  defp tag_without_hash(tag_title), do: tag_title

  defp existing_tag_or_data(tag_title) do
    case Events.get_tag_by_title(tag_title) do
      %Tag{} = tag -> %{title: tag.title, id: tag.id}
      nil -> %{title: tag_title}
    end
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
