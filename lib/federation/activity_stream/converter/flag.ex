defmodule Mobilizon.Federation.ActivityStream.Converter.Flag do
  @moduledoc """
  Flag converter.

  This module allows to convert reports from ActivityStream format to our own
  internal one, and back.

  Note: Reports are named Flag in AS.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.Report

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}

  @behaviour Converter

  defimpl Convertible, for: Report do
    alias Mobilizon.Federation.ActivityStream.Converter.Flag, as: FlagConverter

    defdelegate model_to_as(report), to: FlagConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(object) do
    with params <- as_to_model(object) do
      %{
        "reporter_id" => params["reporter"].id,
        "uri" => params["uri"],
        "content" => params["content"],
        "reported_id" => params["reported"].id,
        "events" => params["events"],
        "comments" => params["comments"]
      }
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(Report.t()) :: map
  def model_to_as(%Report{} = report) do
    object =
      [report.reported.url] ++
        Enum.map(report.comments, fn comment -> comment.url end) ++
        Enum.map(report.events, & &1.url)

    %{
      "type" => "Flag",
      "actor" => Relay.get_actor().url,
      "id" => report.url,
      "content" => report.content,
      "object" => object
    }
  end

  @spec as_to_model(map) :: map
  def as_to_model(%{"object" => objects} = object) do
    with {:ok, %Actor{} = reporter} <-
           ActivityPubActor.get_or_fetch_actor_by_url(object["actor"]),
         %Actor{} = reported <- find_reported(objects),
         %{events: events, comments: comments} <- find_events_and_comments(objects) do
      %{
        "reporter" => reporter,
        "uri" => object["id"],
        "content" => object["content"],
        "reported" => reported,
        "events" => events,
        "comments" => comments
      }
    end
  end

  @spec find_reported(list(String.t())) :: Actor.t() | nil
  defp find_reported(objects) do
    Enum.reduce_while(objects, nil, fn url, _ ->
      case ActivityPubActor.get_or_fetch_actor_by_url(url) do
        {:ok, %Actor{} = actor} ->
          {:halt, actor}

        _ ->
          {:cont, nil}
      end
    end)
  end

  defp find_events_and_comments(objects) do
    objects
    |> Enum.map(&ActivityPub.fetch_object_from_url/1)
    |> Enum.reduce(%{comments: [], events: []}, fn res, acc ->
      case res do
        {:ok, %Event{} = event} ->
          Map.put(acc, :events, [event | acc.events])

        {:ok, %Comment{} = comment} ->
          Map.put(acc, :comments, [comment | acc.comments])

        _ ->
          acc
      end
    end)
  end
end
