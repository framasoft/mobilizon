defmodule MobilizonWeb.Resolvers.Tag do
  @moduledoc """
  Handles the tag-related GraphQL calls
  """
  require Logger
  alias Mobilizon.Events.Event
  alias Mobilizon.Events.Tag

  def list_tags(_parent, %{page: page, limit: limit}, _resolution) do
    tags = Mobilizon.Events.list_tags(page, limit)

    {:ok, tags}
  end

  @doc """
  Retrieve the list of tags for an event
  """
  def list_tags_for_event(%Event{id: id}, _args, _resolution) do
    {:ok, Mobilizon.Events.list_tags_for_event(id)}
  end

  @doc """
  Retrieve the list of related tags for a given tag ID
  """
  def get_related_tags(_parent, %{tag_id: tag_id}, _resolution) do
    with %Tag{} = tag <- Mobilizon.Events.get_tag!(tag_id),
         tags <- Mobilizon.Events.tag_neighbors(tag) do
      {:ok, tags}
    end
  end

  @doc """
  Retrieve the list of related tags for a parent tag
  """
  def get_related_tags(%Tag{} = tag, _args, _resolution) do
    with tags <- Mobilizon.Events.tag_neighbors(tag) do
      {:ok, tags}
    end
  end
end
