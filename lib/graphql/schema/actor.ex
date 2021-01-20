defmodule Mobilizon.GraphQL.Schema.ActorInterface do
  @moduledoc """
  Schema representation for Actor
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.Actor
  alias Mobilizon.GraphQL.Resolvers.Actor, as: ActorResolver
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.Actors.FollowerType)
  import_types(Schema.EventType)

  @desc "An ActivityPub actor"
  interface :actor do
    field(:id, :id, description: "Internal ID for this actor")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")

    field(:avatar, :media, description: "The actor's avatar media")
    field(:banner, :media, description: "The actor's banner media")

    # These one should have a privacy setting
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    field(:media_size, :integer, description: "The total size of the media from this actor")

    resolve_type(fn
      %Actor{type: :Person}, _ ->
        :person

      %Actor{type: :Group}, _ ->
        :group

      %Actor{type: :Application}, _ ->
        :application

      _, _ ->
        nil
    end)
  end

  @desc "The list of types an actor can be"
  enum :actor_type do
    value(:Person, description: "An ActivityPub Person")
    value(:Application, description: "An ActivityPub Application")
    value(:Group, description: "An ActivityPub Group")
    value(:Organization, description: "An ActivityPub Organization")
    value(:Service, description: "An ActivityPub Service")
  end

  object :actor_mutations do
    @desc "Suspend an actor"
    field :suspend_profile, :deleted_object do
      arg(:id, non_null(:id), description: "The remote profile ID to suspend")
      resolve(&ActorResolver.suspend_profile/3)
    end

    @desc "Unsuspend an actor"
    field :unsuspend_profile, :actor do
      arg(:id, non_null(:id), description: "The remote profile ID to unsuspend")
      resolve(&ActorResolver.unsuspend_profile/3)
    end

    @desc "Refresh a profile"
    field :refresh_profile, :actor do
      arg(:id, non_null(:id), description: "The remote profile ID to refresh")
      resolve(&ActorResolver.refresh_profile/3)
    end
  end
end
