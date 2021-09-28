alias Mobilizon.Federation.ActivityPub.Types.{
  Actors,
  Comments,
  Discussions,
  Entity,
  Events,
  Managable,
  Members,
  Ownable,
  Posts,
  Resources,
  Todos,
  TodoLists,
  Tombstones
}

alias Mobilizon.Actors.{Actor, Member}
alias Mobilizon.Events.Event
alias Mobilizon.Discussions.{Comment, Discussion}
alias Mobilizon.Federation.ActivityPub.Permission
alias Mobilizon.Posts.Post
alias Mobilizon.Resources.Resource
alias Mobilizon.Todos.{Todo, TodoList}
alias Mobilizon.Federation.ActivityStream
alias Mobilizon.Tombstone

defmodule Mobilizon.Federation.ActivityPub.Types.Entity do
  @moduledoc """
  ActivityPub entity behaviour
  """
  @type t :: %{required(:id) => any(), optional(:url) => String.t(), optional(atom()) => any()}

  @callback create(data :: any(), additionnal :: map()) ::
              {:ok, t(), ActivityStream.t()} | {:error, any()}

  @callback update(structure :: t(), attrs :: map(), additionnal :: map()) ::
              {:ok, t(), ActivityStream.t()} | {:error, any()}

  @callback delete(structure :: t(), actor :: Actor.t(), local :: boolean(), additionnal :: map()) ::
              {:ok, ActivityStream.t(), Actor.t(), t()} | {:error, any()}
end

defprotocol Mobilizon.Federation.ActivityPub.Types.Managable do
  @moduledoc """
  ActivityPub entity Managable protocol.
  """

  @doc """
  Updates a `Managable` entity with the appropriate attributes and returns the updated entity and an activitystream representation for it
  """
  @spec update(Entity.t(), map(), map()) ::
          {:ok, Entity.t(), ActivityStream.t()} | {:error, any()}
  def update(entity, attrs, additionnal)

  @doc "Deletes an entity and returns the activitystream representation for it"
  @spec delete(Entity.t(), Actor.t(), boolean(), map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Entity.t()} | {:error, any()}
  def delete(entity, actor, local, additionnal)
end

defprotocol Mobilizon.Federation.ActivityPub.Types.Ownable do
  @doc "Returns an eventual group for the entity"
  @spec group_actor(Entity.t()) :: Actor.t() | nil
  def group_actor(entity)

  @doc "Returns the actor for the entity"
  @spec actor(Entity.t()) :: Actor.t() | nil
  def actor(entity)

  @doc """
  Returns the list of permissions for an entity
  """
  @spec permissions(Entity.t()) :: Permission.t()
  def permissions(entity)
end

defimpl Managable, for: Event do
  @spec update(Event.t(), map, map) ::
          {:error, atom() | Ecto.Changeset.t()} | {:ok, Event.t(), ActivityStream.t()}
  defdelegate update(entity, attrs, additionnal), to: Events

  @spec delete(entity :: Event.t(), actor :: Actor.t(), local :: boolean(), additionnal :: map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Event.t()} | {:error, atom() | Ecto.Changeset.t()}
  defdelegate delete(entity, actor, local, additionnal), to: Events
end

defimpl Ownable, for: Event do
  @spec group_actor(Event.t()) :: Actor.t() | nil
  defdelegate group_actor(entity), to: Events
  @spec actor(Event.t()) :: Actor.t() | nil
  defdelegate actor(entity), to: Events
  @spec permissions(Event.t()) :: Permission.t()
  defdelegate permissions(entity), to: Events
end

defimpl Managable, for: Comment do
  @spec update(Comment.t(), map, map) ::
          {:error, Ecto.Changeset.t()} | {:ok, Comment.t(), ActivityStream.t()}
  defdelegate update(entity, attrs, additionnal), to: Comments

  @spec delete(Comment.t(), Actor.t(), boolean, map) ::
          {:error, Ecto.Changeset.t()} | {:ok, ActivityStream.t(), Actor.t(), Comment.t()}
  defdelegate delete(entity, actor, local, additionnal), to: Comments
end

defimpl Ownable, for: Comment do
  defdelegate group_actor(entity), to: Comments
  defdelegate actor(entity), to: Comments
  defdelegate permissions(entity), to: Comments
end

defimpl Managable, for: Post do
  defdelegate update(entity, attrs, additionnal), to: Posts
  defdelegate delete(entity, actor, local, additionnal), to: Posts
end

defimpl Ownable, for: Post do
  defdelegate group_actor(entity), to: Posts
  defdelegate actor(entity), to: Posts
  defdelegate permissions(entity), to: Posts
end

defimpl Managable, for: Actor do
  defdelegate update(entity, attrs, additionnal), to: Actors
  defdelegate delete(entity, actor, local, additionnal), to: Actors
end

defimpl Ownable, for: Actor do
  defdelegate group_actor(entity), to: Actors
  defdelegate actor(entity), to: Actors
  defdelegate permissions(entity), to: Actors
end

defimpl Managable, for: TodoList do
  defdelegate update(entity, attrs, additionnal), to: TodoLists
  defdelegate delete(entity, actor, local, additionnal), to: TodoLists
end

defimpl Ownable, for: TodoList do
  defdelegate group_actor(entity), to: TodoLists
  defdelegate actor(entity), to: TodoLists
  defdelegate permissions(entity), to: TodoLists
end

defimpl Managable, for: Todo do
  defdelegate update(entity, attrs, additionnal), to: Todos
  defdelegate delete(entity, actor, local, additionnal), to: Todos
end

defimpl Ownable, for: Todo do
  defdelegate group_actor(entity), to: Todos
  defdelegate actor(entity), to: Todos
  defdelegate permissions(entity), to: Todos
end

defimpl Managable, for: Resource do
  defdelegate update(entity, attrs, additionnal), to: Resources
  defdelegate delete(entity, actor, local, additionnal), to: Resources
end

defimpl Ownable, for: Resource do
  defdelegate group_actor(entity), to: Resources
  defdelegate actor(entity), to: Resources
  defdelegate permissions(entity), to: Resources
end

defimpl Managable, for: Discussion do
  defdelegate update(entity, attrs, additionnal), to: Discussions
  defdelegate delete(entity, actor, local, additionnal), to: Discussions
end

defimpl Ownable, for: Discussion do
  defdelegate group_actor(entity), to: Discussions
  defdelegate actor(entity), to: Discussions
  defdelegate permissions(entity), to: Discussions
end

defimpl Ownable, for: Tombstone do
  defdelegate group_actor(entity), to: Tombstones
  defdelegate actor(entity), to: Tombstones
  defdelegate permissions(entity), to: Tombstones
end

defimpl Managable, for: Member do
  defdelegate update(entity, attrs, additionnal), to: Members
  defdelegate delete(entity, actor, local, additionnal), to: Members
end
