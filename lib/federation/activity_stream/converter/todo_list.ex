defmodule Mobilizon.Federation.ActivityStream.Converter.TodoList do
  @moduledoc """
  TodoList converter.

  This module allows to convert todo lists from ActivityStream format to our own
  internal one, and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Todos.TodoList

  @behaviour Converter

  defimpl Convertible, for: TodoList do
    alias Mobilizon.Federation.ActivityStream.Converter.TodoList, as: TodoListConverter

    defdelegate model_to_as(report), to: TodoListConverter
  end

  @doc """
  Convert an todo list struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(TodoList.t()) :: map
  def model_to_as(%TodoList{actor: %Actor{url: group_url} = _group} = todo_list) do
    %{
      "type" => "TodoList",
      "actor" => group_url,
      "id" => todo_list.url,
      "name" => todo_list.title,
      "published" => todo_list.published_at |> DateTime.to_iso8601()
    }
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(%{"type" => "TodoList", "actor" => actor_url} = object) do
    case ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      {:ok, %Actor{type: :Group, id: group_id} = _group} ->
        %{
          title: object["name"],
          url: object["id"],
          actor_id: group_id,
          published_at: object["published"]
        }

      _ ->
        {:error, :group_not_found}
    end
  end
end
