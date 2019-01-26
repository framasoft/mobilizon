defmodule MobilizonWeb.Schema do
  @moduledoc """
  GraphQL schema representation
  """
  use Absinthe.Schema

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.{Event, Comment, Participant}

  import_types(MobilizonWeb.Schema.Custom.UUID)
  import_types(MobilizonWeb.Schema.Custom.Point)
  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)

  import_types(MobilizonWeb.Schema.ActorInterface)
  import_types(MobilizonWeb.Schema.Actors.PersonType)
  import_types(MobilizonWeb.Schema.Actors.GroupType)
  import_types(MobilizonWeb.Schema.CommentType)

  alias MobilizonWeb.Resolvers

  @desc "A struct containing the id of the deleted object"
  object :deleted_object do
    field(:id, :integer)
  end

  @desc "A JWT and the associated user ID"
  object :login do
    field(:token, non_null(:string), description: "A JWT Token for this session")
    field(:user, non_null(:user), description: "The user associated to this session")
  end

  @desc "A picture"
  object :picture do
    field(:url, :string, description: "The URL for this picture")
    field(:url_thumbnail, :string, description: "The URL for this picture's thumbnail")
  end

  @desc """
  Represents a notification for an user
  """
  object :notification do
    field(:id, :integer, description: "The notification ID")
    field(:user, :user, description: "The user to transmit the notification to")
    field(:actor, :actor, description: "The notification target profile")

    field(:activity_type, :integer,
      description:
        "Whether the notification is about a follow, group join, event change or comment"
    )

    field(:target_object, :object, description: "The object responsible for the notification")
    field(:summary, :string, description: "Text inside the notification")
    field(:seen, :boolean, description: "Whether or not the notification was seen by the user")
    field(:published, :datetime, description: "Datetime when the notification was published")
  end

  union :object do
    types([:event, :person, :group, :comment, :follower, :member, :participant])

    resolve_type(fn
      %Actor{type: :Person}, _ ->
        :person

      %Actor{type: :Group}, _ ->
        :group

      %Event{}, _ ->
        :event

      %Comment{}, _ ->
        :comment

      %Follower{}, _ ->
        :follower

      %Member{}, _ ->
        :member

      %Participant{}, _ ->
        :participant
    end)
  end

  @desc "A search result"
  union :search_result do
    types([:event, :person, :group])

    resolve_type(fn
      %Actor{type: :Person}, _ ->
        :person

      %Actor{type: :Group}, _ ->
        :group

      %Event{}, _ ->
        :event
    end)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Actors, Actors.data())
      |> Dataloader.add_source(Events, Events.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  @desc """
  Root Query
  """
  query do
    @desc "Get all events"
    field :events, list_of(:event) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.list_events/3)
    end

    @desc "Get all groups"
    field :groups, list_of(:group) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Group.list_groups/3)
    end

    @desc "Search through events, persons and groups"
    field :search, list_of(:search_result) do
      arg(:search, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.search_events_and_actors/3)
    end

    @desc "Get an event by uuid"
    field :event, :event do
      arg(:uuid, non_null(:uuid))
      resolve(&Resolvers.Event.find_event/3)
    end

    @desc "Get all participants for an event uuid"
    field :participants, list_of(:participant) do
      arg(:uuid, non_null(:uuid))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.list_participants_for_event/3)
    end

    @desc "Get a group by it's preferred username"
    field :group, :group do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.Group.find_group/3)
    end

    @desc "Get an user"
    field :user, :user do
      arg(:id, non_null(:id))
      resolve(&Resolvers.User.find_user/3)
    end

    @desc "Get the current user"
    field :logged_user, :user do
      resolve(&Resolvers.User.get_current_user/3)
    end

    @desc "Get the current actor for the logged-in user"
    field :logged_person, :person do
      resolve(&Resolvers.Person.get_current_person/3)
    end

    @desc "Get a person by it's preferred username"
    field :person, :person do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.Person.find_person/3)
    end

    @desc "Get the persons for an user"
    field :identities, list_of(:person) do
      resolve(&Resolvers.Person.identities/3)
    end

    @desc "Get the list of categories"
    field :categories, non_null(list_of(:category)) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Category.list_categories/3)
    end
  end

  @desc """
  Root Mutation
  """
  mutation do
    @desc "Create an event"
    field :create_event, type: :event do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:begins_on, non_null(:datetime))
      arg(:ends_on, :datetime)
      arg(:state, :integer)
      arg(:status, :integer)
      arg(:public, :boolean)
      arg(:thumbnail, :string)
      arg(:large_image, :string)
      arg(:publish_at, :datetime)
      arg(:online_address, :string)
      arg(:phone_address, :string)
      arg(:organizer_actor_id, non_null(:id))
      arg(:category, non_null(:string))

      resolve(&Resolvers.Event.create_event/3)
    end

    @desc "Delete an event"
    field :delete_event, :deleted_object do
      arg(:event_id, non_null(:integer))
      arg(:actor_id, non_null(:integer))

      resolve(&Resolvers.Event.delete_event/3)
    end

    @desc "Create a comment"
    field :create_comment, type: :comment do
      arg(:text, non_null(:string))
      arg(:actor_username, non_null(:string))

      resolve(&Resolvers.Comment.create_comment/3)
    end

    @desc "Create a category with a title, description and picture"
    field :create_category, type: :category do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:picture, non_null(:upload))
      resolve(&Resolvers.Category.create_category/3)
    end

    @desc "Create an user"
    field :create_user, type: :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:username, non_null(:string))

      resolve(&Resolvers.User.create_user_actor/3)
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string))
      resolve(&Resolvers.User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.reset_password/3)
    end

    @desc "Login an user"
    field :login, :login do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&Resolvers.User.login_user/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.User.change_default_actor/3)
    end

    @desc "Create a new person for user"
    field :create_person, :person do
      arg(:preferred_username, non_null(:string))
      arg(:name, :string, description: "The displayed name for the new profile")

      arg(:description, :string, description: "The summary for the new profile", default_value: "")

      resolve(&Resolvers.Person.create_person/3)
    end

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

    # @desc "Upload a picture"
    # field :upload_picture, :picture do
    #   arg(:file, non_null(:upload))
    #   resolve(&Resolvers.Upload.upload_picture/3)
    # end
  end
end
