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
alias Mobilizon.Posts.Post
alias Mobilizon.Resources.Resource
alias Mobilizon.Todos.{Todo, TodoList}
alias Mobilizon.Federation.ActivityStream
alias Mobilizon.Tombstone

defmodule Mobilizon.Federation.ActivityPub.Types.Entity do
  @moduledoc """
  ActivityPub entity behaviour
  """
  @type t :: %{id: String.t()}

  @callback create(data :: any(), additionnal :: map()) ::
              {:ok, t(), ActivityStream.t()}

  @callback update(struct :: t(), attrs :: map(), additionnal :: map()) ::
              {:ok, t(), ActivityStream.t()}

  @callback delete(struct :: t(), Actor.t(), local :: boolean(), map()) ::
              {:ok, ActivityStream.t(), Actor.t(), t()}
end

defprotocol Mobilizon.Federation.ActivityPub.Types.Managable do
  @moduledoc """
  ActivityPub entity Managable protocol.
  """

  @spec update(Entity.t(), map(), map()) :: {:ok, Entity.t(), ActivityStream.t()}
  @doc """
  Updates a `Managable` entity with the appropriate attributes and returns the updated entity and an activitystream representation for it
  """
  def update(entity, attrs, additionnal)

  @spec delete(Entity.t(), Actor.t(), boolean(), map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Entity.t()}
  @doc "Deletes an entity and returns the activitystream representation for it"
  def delete(entity, actor, local, additionnal)
end

defprotocol Mobilizon.Federation.ActivityPub.Types.Ownable do
  @type group_role :: :member | :moderator | :administrator | nil

  @spec group_actor(Entity.t()) :: Actor.t() | nil
  @doc "Returns an eventual group for the entity"
  def group_actor(entity)

  @spec actor(Entity.t()) :: Actor.t() | nil
  @doc "Returns the actor for the entity"
  def actor(entity)

  @spec role_needed_to_update(Entity.t()) :: group_role()
  def role_needed_to_update(entity)

  @spec role_needed_to_delete(Entity.t()) :: group_role()
  def role_needed_to_delete(entity)
end

defimpl Managable, for: Event do
  defdelegate update(entity, attrs, additionnal), to: Events
  defdelegate delete(entity, actor, local, additionnal), to: Events
end

defimpl Ownable, for: Event do
  defdelegate group_actor(entity), to: Events
  defdelegate actor(entity), to: Events
  defdelegate role_needed_to_update(entity), to: Events
  defdelegate role_needed_to_delete(entity), to: Events
end

defimpl Managable, for: Comment do
  defdelegate update(entity, attrs, additionnal), to: Comments
  defdelegate delete(entity, actor, local, additionnal), to: Comments
end

defimpl Ownable, for: Comment do
  defdelegate group_actor(entity), to: Comments
  defdelegate actor(entity), to: Comments
  defdelegate role_needed_to_update(entity), to: Comments
  defdelegate role_needed_to_delete(entity), to: Comments
end

defimpl Managable, for: Post do
  defdelegate update(entity, attrs, additionnal), to: Posts
  defdelegate delete(entity, actor, local, additionnal), to: Posts
end

defimpl Ownable, for: Post do
  defdelegate group_actor(entity), to: Posts
  defdelegate actor(entity), to: Posts
  defdelegate role_needed_to_update(entity), to: Posts
  defdelegate role_needed_to_delete(entity), to: Posts
end

defimpl Managable, for: Actor do
  defdelegate update(entity, attrs, additionnal), to: Actors
  defdelegate delete(entity, actor, local, additionnal), to: Actors
end

defimpl Ownable, for: Actor do
  defdelegate group_actor(entity), to: Actors
  defdelegate actor(entity), to: Actors
  defdelegate role_needed_to_update(entity), to: Actors
  defdelegate role_needed_to_delete(entity), to: Actors
end

defimpl Managable, for: TodoList do
  defdelegate update(entity, attrs, additionnal), to: TodoLists
  defdelegate delete(entity, actor, local, additionnal), to: TodoLists
end

defimpl Ownable, for: TodoList do
  defdelegate group_actor(entity), to: TodoLists
  defdelegate actor(entity), to: TodoLists
  defdelegate role_needed_to_update(entity), to: TodoLists
  defdelegate role_needed_to_delete(entity), to: TodoLists
end

defimpl Managable, for: Todo do
  defdelegate update(entity, attrs, additionnal), to: Todos
  defdelegate delete(entity, actor, local, additionnal), to: Todos
end

defimpl Ownable, for: Todo do
  defdelegate group_actor(entity), to: Todos
  defdelegate actor(entity), to: Todos
  defdelegate role_needed_to_update(entity), to: Todos
  defdelegate role_needed_to_delete(entity), to: Todos
end

defimpl Managable, for: Resource do
  defdelegate update(entity, attrs, additionnal), to: Resources
  defdelegate delete(entity, actor, local, additionnal), to: Resources
end

defimpl Ownable, for: Resource do
  defdelegate group_actor(entity), to: Resources
  defdelegate actor(entity), to: Resources
  defdelegate role_needed_to_update(entity), to: Resources
  defdelegate role_needed_to_delete(entity), to: Resources
end

defimpl Managable, for: Discussion do
  defdelegate update(entity, attrs, additionnal), to: Discussions
  defdelegate delete(entity, actor, local, additionnal), to: Discussions
end

defimpl Ownable, for: Discussion do
  defdelegate group_actor(entity), to: Discussions
  defdelegate actor(entity), to: Discussions
  defdelegate role_needed_to_update(entity), to: Discussions
  defdelegate role_needed_to_delete(entity), to: Discussions
end

defimpl Ownable, for: Tombstone do
  defdelegate group_actor(entity), to: Tombstones
  defdelegate actor(entity), to: Tombstones
  defdelegate role_needed_to_update(entity), to: Tombstones
  defdelegate role_needed_to_delete(entity), to: Tombstones
end

defimpl Managable, for: Member do
  defdelegate update(entity, attrs, additionnal), to: Members
  defdelegate delete(entity, actor, local, additionnal), to: Members
end
