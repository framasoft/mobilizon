defmodule Mobilizon.Service.ActivityPub.Converters.Flag do
  @moduledoc """
  Flag converter

  This module allows to convert reports from ActivityStream format to our own internal one, and back.

  Note: Reports are named Flag in AS.
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.Report
  alias Mobilizon.Service.ActivityPub.Converter

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map()
  def as_to_model_data(object) do
    with params <- as_to_model(object) do
      %{
        "reporter_id" => params["reporter"].id,
        "uri" => params["uri"],
        "content" => params["content"],
        "reported_id" => params["reported"].id,
        "event_id" => (!is_nil(params["event"]) && params["event"].id) || nil,
        "comments" => params["comments"]
      }
    end
  end

  def as_to_model(%{"object" => objects} = object) do
    with {:ok, %Actor{} = reporter} <- Actors.get_actor_by_url(object["actor"]),
         %Actor{} = reported <-
           Enum.reduce_while(objects, nil, fn url, _ ->
             case Actors.get_actor_by_url(url) do
               {:ok, %Actor{} = actor} ->
                 {:halt, actor}

               _ ->
                 {:cont, nil}
             end
           end),
         event <-
           Enum.reduce_while(objects, nil, fn url, _ ->
             case Events.get_event_by_url(url) do
               %Event{} = event ->
                 {:halt, event}

               _ ->
                 {:cont, nil}
             end
           end),

         # Remove the reported user from the object list.
         comments <-
           Enum.filter(objects, fn url ->
             !(url == reported.url || (!is_nil(event) && event.url == url))
           end),
         comments <- Enum.map(comments, &Events.get_comment_from_url/1) do
      %{
        "reporter" => reporter,
        "uri" => object["id"],
        "content" => object["content"],
        "reported" => reported,
        "event" => event,
        "comments" => comments
      }
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(EventModel.t()) :: map()
  def model_to_as(%Report{} = report) do
    %{
      "type" => "Flag",
      "to" => ["https://www.w3.org/ns/activitystreams#Public"],
      "actor" => report.reporter.url,
      "id" => report.url
    }
  end
end
