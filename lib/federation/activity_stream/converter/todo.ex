defmodule Mobilizon.Federation.ActivityStream.Converter.Todo do
  @moduledoc """
  TodoList converter.

  This module allows to convert todo lists from ActivityStream format to our own
  internal one, and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Todos
  alias Mobilizon.Todos.{Todo, TodoList}

  @behaviour Converter

  defimpl Convertible, for: Todo do
    alias Mobilizon.Federation.ActivityStream.Converter.Todo, as: TodoConverter

    defdelegate model_to_as(todo), to: TodoConverter
  end

  @doc """
  Convert an todo list struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(Todo.t()) :: map
  def model_to_as(
        %Todo{
          todo_list: %TodoList{actor: %Actor{url: group_url} = _group, url: todo_list_url},
          creator: %Actor{url: creator_url}
        } = todo
      ) do
    %{
      "type" => "Todo",
      "actor" => creator_url,
      "attributedTo" => group_url,
      "id" => todo.url,
      "name" => todo.title,
      "status" => todo.status,
      "todoList" => todo_list_url,
      "published" => todo.published_at |> DateTime.to_iso8601()
    }
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(
        %{"type" => "Todo", "actor" => actor_url, "todoList" => todo_list_url} = object
      ) do
    with {:ok, %Actor{id: creator_id} = _creator} <-
           ActivityPubActor.get_or_fetch_actor_by_url(actor_url),
         {:todo_list, %TodoList{id: todo_list_id}} <-
           {:todo_list, Todos.get_todo_list_by_url(todo_list_url)} do
      %{
        title: object["name"],
        status: object["status"],
        url: object["id"],
        todo_list_id: todo_list_id,
        creator_id: creator_id,
        published_at: object["published"]
      }
    else
      {:todo_list, nil} ->
        with {:ok, %TodoList{}} <- ActivityPub.fetch_object_from_url(todo_list_url) do
          as_to_model_data(object)
        end
    end
  end
end
