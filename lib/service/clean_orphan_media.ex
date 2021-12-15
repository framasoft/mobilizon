defmodule Mobilizon.Service.CleanOrphanMedia do
  @moduledoc """
  Service to clean orphan media
  """

  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media

  @doc """
  Clean orphan media

  Remove media that is not attached to an entity, such as media uploads that were never used in entities.

  Options:
   * `grace_period` how old in hours can the media be before it's taken into account for deletion
   * `dry_run` just return the media that would have been deleted, don't actually delete it
  """
  @spec clean(Keyword.t()) :: {:ok, list(Media.t())}
  def clean(opts \\ []) do
    medias = Medias.find_media_to_clean(opts)

    if Keyword.get(opts, :dry_run, false) do
      {:ok, medias}
    else
      Enum.each(medias, fn media_list ->
        Enum.each(media_list, fn media ->
          Medias.delete_media(media, ignore_file_not_found: true)
        end)
      end)

      {:ok, medias}
    end
  end
end
