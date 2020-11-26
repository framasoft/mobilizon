defmodule Mobilizon.Service.CleanOrphanMedia do
  @moduledoc """
  Service to clean orphan media
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media
  alias Mobilizon.Storage.Repo
  import Ecto.Query

  @grace_period Mobilizon.Config.get([:instance, :orphan_upload_grace_period_hours], 48)

  @doc """
  Clean orphan media

  Remove media that is not attached to an entity, such as media uploads that were never used in entities.

  Options:
   * `grace_period` how old in hours can the media be before it's taken into account for deletion
   * `dry_run` just return the media that would have been deleted, don't actually delete it
  """
  @spec clean(Keyword.t()) :: {:ok, list(Media.t())} | {:error, String.t()}
  def clean(opts \\ []) do
    medias = find_media(opts)

    if Keyword.get(opts, :dry_run, false) do
      {:ok, medias}
    else
      Enum.each(medias, fn media ->
        Medias.delete_media(media, ignore_file_not_found: true)
      end)

      {:ok, medias}
    end
  end

  @spec find_media(Keyword.t()) :: list(Media.t())
  defp find_media(opts) do
    grace_period = Keyword.get(opts, :grace_period, @grace_period)
    expiration_date = DateTime.add(DateTime.utc_now(), grace_period * -3600)

    Media
    |> where([m], m.inserted_at < ^expiration_date)
    |> join(:inner, [m], a in Actor)
    |> where([_m, a], is_nil(a.domain))
    |> join(:left, [m], e in assoc(m, :events))
    |> join(:left, [m], ep in assoc(m, :event_picture))
    |> join(:left, [m], p in assoc(m, :posts))
    |> join(:left, [m], pp in assoc(m, :posts_picture))
    |> join(:left, [m], c in assoc(m, :comments))
    |> where([_m, _a, e], is_nil(e.id))
    |> where([_m, _a, _e, ep], is_nil(ep.id))
    |> where([_m, _a, _e, _ep, p], is_nil(p.id))
    |> where([_m, _a, _e, _ep, _p, pp], is_nil(pp.id))
    |> where([_m, _a, _e, _ep, _p, _pp, c], is_nil(c.id))
    |> distinct(true)
    |> Repo.all()
  end
end
