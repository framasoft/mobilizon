defmodule Mobilizon.Federation.ActivityStream.Converter.Utils do
  @moduledoc """
  Various utils for converters.
  """

  alias Mobilizon.{Actors, Addresses, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Tag
  alias Mobilizon.Medias.Media
  alias Mobilizon.Mention
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.Converter.Address, as: AddressConverter
  alias Mobilizon.Federation.ActivityStream.Converter.Media, as: MediaConverter

  alias Mobilizon.Web.Endpoint

  require Logger

  @banner_picture_name "Banner"

  @spec fetch_tags([String.t()]) :: [Tag.t()]
  def fetch_tags(tags) when is_list(tags) do
    Logger.debug("fetching tags")
    Logger.debug(inspect(tags))

    tags |> Enum.flat_map(&fetch_tag/1) |> Enum.uniq() |> Enum.map(&existing_tag_or_data/1)
  end

  def fetch_tags(_), do: []

  @spec fetch_mentions([map()]) :: [map()]
  def fetch_mentions(mentions) when is_list(mentions) do
    Logger.debug("fetching mentions")

    Enum.reduce(mentions, [], fn mention, acc -> create_mention(mention, acc) end)
  end

  def fetch_mentions(_), do: []

  def fetch_actors(actors) when is_list(actors) do
    Logger.debug("fetching contacts")
    actors |> Enum.map(& &1.id) |> Enum.filter(& &1) |> Enum.map(&Actors.get_actor/1)
  end

  def fetch_actors(_), do: []

  @spec build_tags([Tag.t()]) :: [map()]
  def build_tags(tags) do
    Enum.map(tags, fn %Tag{} = tag ->
      %{
        "href" => Endpoint.url() <> "/tags/#{tag.slug}",
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
      "name" => "@#{Actor.preferred_username_and_domain(actor)}",
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

  defp fetch_tag(tag) when is_binary(tag), do: [tag_without_hash(tag)]

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

  defp create_mention(mention, acc) when is_map(mention) do
    with true <- mention["type"] == "Mention",
         {:ok, %Actor{id: actor_id}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(mention["href"]) do
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

  @spec maybe_fetch_actor_and_attributed_to_id(map()) ::
          {:ok, Actor.t(), Actor.t() | nil} | {:error, atom()}
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(attributed_to_url) do
    case fetch_actor(actor_url) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor, nil}

      {:error, err} ->
        {:error, err}
    end
  end

  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(actor_url) do
    case fetch_actor(attributed_to_url) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor, nil}

      {:error, err} ->
        {:error, err}
    end
  end

  # Only when both actor and attributedTo fields are both filled is when we can return both
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when actor_url != attributed_to_url do
    with {:ok, %Actor{} = actor} <- fetch_actor(actor_url),
         {:ok, %Actor{} = attributed_to} <- fetch_actor(attributed_to_url) do
      {:ok, actor, attributed_to}
    else
      {:error, err} ->
        {:error, err}
    end
  end

  # If we only have attributedTo and no actor, take attributedTo as the actor
  def maybe_fetch_actor_and_attributed_to_id(%{
        "attributedTo" => attributed_to_url
      }) do
    case fetch_actor(attributed_to_url) do
      {:ok, %Actor{} = attributed_to} -> {:ok, attributed_to, nil}
      {:error, err} -> {:error, err}
    end
  end

  def maybe_fetch_actor_and_attributed_to_id(_), do: {:error, :no_actor_found}

  @spec fetch_actor(String.t()) :: {:ok, Actor.t()} | {:error, atom()}
  def fetch_actor(actor_url) do
    case ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      {:ok, %Actor{suspended: false} = actor} ->
        {:ok, actor}

      {:ok, %Actor{suspended: true} = _actor} ->
        {:error, :actor_suspended}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec process_pictures(map(), integer()) :: Keyword.t()
  def process_pictures(object, actor_id) do
    attachements = Map.get(object, "attachment", [])

    {banner, media_attachements} = get_medias(attachements)

    media_attachements_map =
      media_attachements
      |> Enum.map(fn media_attachement ->
        {media_attachement["url"],
         MediaConverter.find_or_create_media(media_attachement, actor_id)}
      end)
      |> Enum.reduce(%{}, fn {old_url, media}, acc ->
        case media do
          {:ok, %Media{} = media} ->
            Map.put(acc, old_url, media)

          _ ->
            acc
        end
      end)

    media_attachements_map_urls =
      media_attachements_map
      |> Enum.map(fn {old_url, new_media} -> {old_url, new_media.file.url} end)
      |> Map.new()

    picture_id =
      case banner do
        banner_map when is_map(banner_map) ->
          case MediaConverter.find_or_create_media(banner_map, actor_id) do
            {:error, _err} ->
              nil

            {:ok, %Media{id: picture_id}} ->
              picture_id
          end

        _ ->
          nil
      end

    description = replace_media_urls_in_body(object["content"], media_attachements_map_urls)
    [description: description, picture_id: picture_id, medias: Map.values(media_attachements_map)]
  end

  defp replace_media_urls_in_body(body, media_urls),
    do:
      Enum.reduce(media_urls, body, fn media_url, body ->
        replace_media_url_in_body(body, media_url)
      end)

  defp replace_media_url_in_body(body, {old_url, new_url}),
    do: String.replace(body, old_url, new_url)

  @spec get_medias(list(map())) :: {map(), list(map())}
  defp get_medias(attachments) do
    banner = get_banner_picture(attachments)
    {banner, Enum.filter(attachments, &(&1["type"] == "Document" && &1["url"] != banner["url"]))}
  end

  @spec get_banner_picture(list(map())) :: map()
  defp get_banner_picture(attachments) do
    # Prefer media with
    media_with_picture_name =
      Enum.find(attachments, &(&1["type"] == "Document" && &1["name"] == @banner_picture_name))

    case media_with_picture_name do
      # If no banner found, use the first media
      nil -> Enum.find(attachments, &(&1["type"] == "Document"))
      media_with_picture_name -> media_with_picture_name
    end
  end

  @spec get_address(map | binary | nil) :: Address.t() | nil
  def get_address(address_url) when is_binary(address_url) do
    get_address(%{"id" => address_url})
  end

  def get_address(%{"id" => url} = map) when is_map(map) and is_binary(url) do
    Logger.debug("Address with an URL, let's check against our own database")

    case Addresses.get_address_by_url(url) do
      %Address{} = address ->
        address

      _ ->
        Logger.debug("not in our database, let's try to create it")
        # This is odd, why do addresses have url instead of just @id?
        map = Map.put(map, "url", map["id"])
        do_get_address(map)
    end
  end

  def get_address(map) when is_map(map) do
    do_get_address(map)
  end

  def get_address(nil), do: nil

  @spec do_get_address(map) :: Address.t() | nil
  defp do_get_address(map) do
    map = AddressConverter.as_to_model_data(map)

    case Addresses.create_address(map) do
      {:ok, %Address{} = address} ->
        address

      _ ->
        nil
    end
  end
end
