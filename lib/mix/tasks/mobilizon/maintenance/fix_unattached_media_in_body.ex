defmodule Mix.Tasks.Mobilizon.Maintenance.FixUnattachedMediaInBody do
  @moduledoc """
  Task to reattach media files that were added in event, post or comment bodies without being attached to their entities.

  This task should only be run once.
  """
  use Mix.Task

  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.{Discussions, Events, Medias, Posts}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Repo
  require Logger

  @preferred_cli_env "prod"

  # TODO: Remove me in Mobilizon 1.2

  @shortdoc "Reattaches inline media from events and posts"
  def run([]) do
    start_mobilizon()

    shell_info("Going to extract pictures from events")
    extract_inline_pictures_from_bodies(Event)
    shell_info("Going to extract pictures from posts")
    extract_inline_pictures_from_bodies(Post)
    shell_info("Going to extract pictures from comments")
    extract_inline_pictures_from_bodies(Comment)
  end

  defp extract_inline_pictures_from_bodies(entity) do
    Repo.transaction(
      fn ->
        entity
        |> Repo.stream()
        |> Stream.map(&extract_pictures(&1))
        |> Stream.map(fn {entity, pics} -> save_entity(entity, pics) end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  defp extract_pictures(entity) do
    extracted_pictures = entity |> get_body() |> parse_body() |> get_media_entities_from_urls()

    attached_picture = entity |> get_picture() |> get_media_entity_from_media_id()
    attached_pictures = [attached_picture] |> Enum.filter(& &1)

    {entity, extracted_pictures ++ attached_pictures}
  end

  defp get_body(%Event{description: description}), do: description
  defp get_body(%Post{body: body}), do: body
  defp get_body(%Comment{text: text}), do: text

  defp get_picture(%Event{picture_id: picture_id}), do: picture_id
  defp get_picture(%Post{picture_id: picture_id}), do: picture_id
  defp get_picture(%Comment{}), do: nil

  defp parse_body(nil), do: []

  defp parse_body(body) do
    with res <- Regex.scan(~r/<img\s[^>]*?src\s*=\s*['\"]([^'\"]*?)['\"][^>]*?>/, body),
         res <- Enum.map(res, fn [_, res] -> res end) do
      res
    end
  end

  defp get_media_entities_from_urls(media_urls) do
    media_urls
    |> Enum.map(fn media_url ->
      # We prefer orphan media, but fallback on already attached media just in case
      Medias.get_unattached_media_by_url(media_url) || Medias.get_media_by_url(media_url)
    end)
    |> Enum.filter(& &1)
  end

  defp get_media_entity_from_media_id(nil), do: nil

  defp get_media_entity_from_media_id(media_id) do
    Medias.get_media(media_id)
  end

  defp save_entity(%Event{} = _event, []), do: :ok

  defp save_entity(%Event{} = event, media) do
    event = Repo.preload(event, [:contacts, :media])
    Events.update_event(event, %{media: media})
  end

  defp save_entity(%Post{} = _post, []), do: :ok

  defp save_entity(%Post{} = post, media) do
    post = Repo.preload(post, [:media])
    Posts.update_post(post, %{media: media})
  end

  defp save_entity(%Comment{} = _comment, []), do: :ok

  defp save_entity(%Comment{} = comment, media) do
    comment = Repo.preload(comment, [:media])
    Discussions.update_comment(comment, %{media: media})
  end
end
