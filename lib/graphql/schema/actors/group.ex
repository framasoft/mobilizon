defmodule Mobilizon.GraphQL.Schema.Actors.GroupType do
  @moduledoc """
  Schema representation for Group.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Addresses

  alias Mobilizon.GraphQL.Resolvers.{
    Activity,
    Discussion,
    Followers,
    Group,
    Media,
    Member,
    Post,
    Resource,
    Todos
  }

  alias Mobilizon.GraphQL.Schema

  import_types(Schema.Actors.MemberType)

  @desc """
  Represents a group of actors
  """
  object :group do
    interfaces([:actor, :interactable, :activity_object])

    field(:id, :id, description: "Internal ID for this group")
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

    field(:visibility, :group_visibility,
      description: "Whether the group can be found and/or promoted"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")

    field(:avatar, :media, description: "The actor's avatar media")
    field(:banner, :media, description: "The actor's banner media")

    field(:physical_address, :address,
      resolve: dataloader(Addresses),
      description: "The type of the event's address"
    )

    # These one should have a privacy setting
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    field(:media_size, :integer,
      resolve: &Media.actor_size/3,
      description: "The total size of the media from this actor"
    )

    # This one should have a privacy setting
    field :organized_events, :paginated_event_list do
      arg(:after_datetime, :datetime,
        default_value: nil,
        description: "Filter events that begin after this datetime"
      )

      arg(:before_datetime, :datetime,
        default_value: nil,
        description: "Filter events that begin before this datetime"
      )

      arg(:page, :integer, default_value: 1, description: "The page in the paginated event list")
      arg(:limit, :integer, default_value: 10, description: "The limit of events per page")
      resolve(&Group.find_events_for_group/3)
      description("A list of the events this actor has organized")
    end

    field :discussions, :paginated_discussion_list do
      resolve(&Discussion.find_discussions_for_actor/3)
      description("A list of the discussions for this group")
    end

    field(:types, :group_type, description: "The type of group : Group, Community,…")

    field(:openness, :openness,
      description: "Whether the group is opened to all or has restricted access"
    )

    field :members, :paginated_member_list do
      arg(:page, :integer, default_value: 1, description: "The page in the paginated member list")
      arg(:limit, :integer, default_value: 10, description: "The limit of members per page")
      arg(:roles, :string, default_value: "", description: "Filter members by their role")
      resolve(&Member.find_members_for_group/3)
      description("A paginated list of group members")
    end

    field :resources, :paginated_resource_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated resource list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of resources per page")
      resolve(&Resource.find_resources_for_group/3)
      description("A paginated list of the resources this group has")
    end

    field :posts, :paginated_post_list do
      arg(:page, :integer, default_value: 1, description: "The page in the paginated post list")
      arg(:limit, :integer, default_value: 10, description: "The limit of posts per page")
      resolve(&Post.find_posts_for_group/3)
      description("A paginated list of the posts this group has")
    end

    field :todo_lists, :paginated_todo_list_list do
      resolve(&Todos.find_todo_lists_for_group/3)
      description("A paginated list of the todo lists this group has")
    end

    field :followers, :paginated_follower_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated followers list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of followers per page")

      arg(:approved, :boolean,
        default_value: nil,
        description: "Used to filter the followers list by approved status"
      )

      resolve(&Followers.find_followers_for_group/3)
      description("A paginated list of the followers this group has")
    end

    field :activity, :paginated_activity_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated activity items list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of activity items per page")

      arg(:type, :activity_type, description: "Filter by type of activity")
      resolve(&Activity.group_activity/3)
      description("The group activity")
    end
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

  @desc """
  A paginated list of groups
  """
  object :paginated_group_list do
    field(:elements, list_of(:group), description: "A list of groups")
    field(:total, :integer, description: "The total number of groups in the list")
  end

  @desc "The list of visibility options for a group"
  enum :group_visibility do
    value(:public, description: "Publicly listed and federated")
    value(:unlisted, description: "Visible only to people with the link - or invited")
    value(:private, description: "Visible only to people with the link - or invited")
  end

  object :group_queries do
    @desc "Get all groups"
    field :groups, :paginated_group_list do
      arg(:preferred_username, :string, default_value: "", description: "Filter by username")
      arg(:name, :string, default_value: "", description: "Filter by name")
      arg(:domain, :string, default_value: "", description: "Filter by domain")

      arg(:local, :boolean,
        default_value: true,
        description: "Filter whether group is local or not"
      )

      arg(:suspended, :boolean, default_value: false, description: "Filter by suspended status")
      arg(:page, :integer, default_value: 1, description: "The page in the paginated group list")
      arg(:limit, :integer, default_value: 10, description: "The limit of groups per page")
      resolve(&Group.list_groups/3)
    end

    @desc "Get a group by its ID"
    field :get_group, :group do
      arg(:id, non_null(:id), description: "The group ID")
      resolve(&Group.get_group/3)
    end

    @desc "Get a group by its preferred username"
    field :group, :group do
      arg(:preferred_username, non_null(:string),
        description: "The group preferred_username, eventually containing their domain if remote"
      )

      resolve(&Group.find_group/3)
    end
  end

  object :group_mutations do
    @desc "Create a group"
    field :create_group, :group do
      arg(:preferred_username, non_null(:string), description: "The name for the group")

      arg(:name, :string, description: "The displayed name for the group")
      arg(:summary, :string, description: "The summary for the group", default_value: "")

      arg(:visibility, :group_visibility,
        description: "The visibility for the group",
        default_value: :public
      )

      arg(:openness, :openness,
        default_value: :invite_only,
        description: "Whether the group can be join freely, with approval or is invite-only."
      )

      arg(:avatar, :media_input,
        description:
          "The avatar for the group, either as an object or directly the ID of an existing media"
      )

      arg(:banner, :media_input,
        description:
          "The banner for the group, either as an object or directly the ID of an existing media"
      )

      arg(:physical_address, :address_input, description: "The physical address for the group")

      resolve(&Group.create_group/3)
    end

    @desc "Update a group"
    field :update_group, :group do
      arg(:id, non_null(:id), description: "The group ID")

      arg(:name, :string, description: "The displayed name for the group")
      arg(:summary, :string, description: "The summary for the group", default_value: "")

      arg(:visibility, :group_visibility, description: "The visibility for the group")

      arg(:openness, :openness,
        description: "Whether the group can be join freely, with approval or is invite-only."
      )

      arg(:manually_approves_followers, :boolean,
        description: "Whether this group approves new followers manually"
      )

      arg(:avatar, :media_input,
        description:
          "The avatar for the group, either as an object or directly the ID of an existing media"
      )

      arg(:banner, :media_input,
        description:
          "The banner for the group, either as an object or directly the ID of an existing media"
      )

      arg(:physical_address, :address_input, description: "The physical address for the group")

      resolve(&Group.update_group/3)
    end

    @desc "Delete a group"
    field :delete_group, :deleted_object do
      arg(:group_id, non_null(:id), description: "The group ID")

      resolve(&Group.delete_group/3)
    end
  end
end
