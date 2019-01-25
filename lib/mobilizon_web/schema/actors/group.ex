defmodule MobilizonWeb.Schema.Actors.GroupType do
  @moduledoc """
  Schema representation for Group
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import_types(MobilizonWeb.Schema.Actors.MemberType)
  alias MobilizonWeb.Resolvers

  @desc """
  Represents a group of actors
  """
  object :group do
    interfaces([:actor])

    field(:id, :id, description: "Internal ID for this group")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")
    field(:keys, :string, description: "The actors RSA Keys")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")
    field(:avatar_url, :string, description: "The actor's avatar url")
    field(:banner_url, :string, description: "The actor's banner url")

    # These one should have a privacy setting
    field(:following, list_of(:follower), description: "List of followings")
    field(:followers, list_of(:follower), description: "List of followers")
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    # This one should have a privacy setting
    field(:organized_events, list_of(:event),
      resolve: dataloader(Events),
      description: "A list of the events this actor has organized"
    )

    field(:types, :group_type, description: "The type of group : Group, Community,…")

    field(:openness, :openness,
      description: "Whether the group is opened to all or has restricted access"
    )

    field(:members, non_null(list_of(:member)), description: "List of group members")
  end

  @desc """
  The types of Group that exist
  """
  enum :group_type do
    value(:group, description: "A private group of persons")
    value(:community, description: "A public group of many actors")
  end

  @desc """
  Describes how an actor is opened to follows
  """
  enum :openness do
    value(:invite_only, description: "The actor can only be followed by invitation")

    value(:moderated, description: "The actor needs to accept the following before it's effective")

    value(:open, description: "The actor is open to followings")
  end

  object :group_queries do
    @desc "Get all groups"
    field :groups, list_of(:group) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Group.list_groups/3)
    end

    @desc "Get a group by it's preferred username"
    field :group, :group do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.Group.find_group/3)
    end
  end

  object :group_mutations do
    @desc "Create a group"
    field :create_group, :group do
      arg(:preferred_username, non_null(:string), description: "The name for the group")
      arg(:name, :string, description: "The displayed name for the group")
      arg(:description, :string, description: "The summary for the group", default_value: "")

      arg(:admin_actor_username, :string,
        description: "The actor's username which will be the admin (otherwise user's default one)"
      )

      resolve(&Resolvers.Group.create_group/3)
    end

    @desc "Delete a group"
    field :delete_group, :deleted_object do
      arg(:group_id, non_null(:integer))
      arg(:actor_id, non_null(:integer))

      resolve(&Resolvers.Group.delete_group/3)
    end
  end
end
