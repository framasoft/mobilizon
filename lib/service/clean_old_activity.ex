defmodule Mobilizon.Service.CleanOldActivity do
  @moduledoc """
  Service to clean old activities
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Storage.Repo
  import Ecto.Query

  @doc """
  Clean old activities

  Remove activities that are older than a certain period

  Options:
   * `grace_period` how old in hours can the media be before it's taken into account for deletion
   * `dry_run` just return the media that would have been deleted, don't actually delete it
  """
  @spec clean(Keyword.t()) :: {:ok, list(Media.t())} | {:error, String.t()}
  def clean(opts \\ []) do
    {query, nb_actors} = find_activities(opts)

    if Keyword.get(opts, :dry_run, false) do
      nb_activities = Repo.aggregate(query, :count)
      {:ok, actors: nb_actors, activities: nb_activities}
    else
      {nb_activities, _} = Repo.delete_all(query)
      {:ok, actors: nb_actors, activities: nb_activities}
    end
  end

  @spec find_activities(Keyword.t()) :: {Ecto.Query.t(), list()}
  defp find_activities(opts) do
    grace_period =
      Keyword.get(opts, :grace_period, Config.get([:instance, :activity_expire_days], 365))

    expiration_date = DateTime.add(DateTime.utc_now(), grace_period * -3600)

    activities_to_keep =
      Keyword.get(
        opts,
        :activity_keep_number,
        Config.get([:instance, :activity_keep_number], 100)
      )

    actor_ids =
      Actor
      |> where(type: :Group)
      |> join(:inner, [ac], a in Activity, on: a.group_id == ac.id)
      |> group_by([ac], ac.id)
      |> having([_ac, a], count(a.id) > ^activities_to_keep)
      |> select([ac], ac.id)
      |> Repo.all()

    query =
      Activity
      |> where([a], a.inserted_at < ^expiration_date)
      |> where([a], a.group_id in ^actor_ids)

    {query, length(actor_ids)}
  end
end
