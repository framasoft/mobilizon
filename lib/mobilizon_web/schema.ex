defmodule MobilizonWeb.Schema do
  use Absinthe.Schema

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.{Event, Comment, Participant}

  import_types(MobilizonWeb.Schema.Custom.UUID)
  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)

  alias MobilizonWeb.Resolvers

  @desc """
  Represents a person identity
  """
  object :person do
    interfaces([:actor])
    field(:user, :user, description: "The user this actor is associated to")

    field(:member_of, list_of(:member), description: "The list of groups this person is member of")

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
  end

  @desc """
  Represents a group of actors
  """
  object :group do
    interfaces([:actor])

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
  Describes how an actor is opened to follows
  """
  enum :openness do
    value(:invite_only, description: "The actor can only be followed by invitation")

    value(:moderated, description: "The actor needs to accept the following before it's effective")

    value(:open, description: "The actor is open to followings")
  end

  @desc """
  The types of Group that exist
  """
  enum :group_type do
    value(:group, description: "A private group of persons")
    value(:community, description: "A public group of many actors")
  end

  @desc "An ActivityPub actor"
  interface :actor do
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

    # This one is for the person itself **only**
    # field(:feed, list_of(:event), description: "List of events the actor sees in his or her feed")

    # field(:memberships, list_of(:member))

    resolve_type(fn
      %Actor{type: :Person}, _ ->
        :person

      %Actor{type: :Group}, _ ->
        :group
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

  @desc "A local user of Mobilizon"
  object :user do
    field(:id, non_null(:id), description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")

    field(:profiles, non_null(list_of(:person)),
      description: "The user's list of profiles (identities)"
    )

    field(:default_actor, non_null(:person), description: "The user's default actor")

    field(:confirmed_at, :datetime,
      description: "The datetime when the user was confirmed/activated"
    )

    field(:confirmation_sent_at, :datetime,
      description: "The datetime the last activation/confirmation token was sent"
    )

    field(:confirmation_token, :string, description: "The account activation/confirmation token")

    field(:reset_password_sent_at, :datetime,
      description: "The datetime last reset password email was sent"
    )

    field(:reset_password_token, :string,
      description: "The token sent when requesting password token"
    )
  end

  @desc "A JWT and the associated user ID"
  object :login do
    field(:token, non_null(:string), description: "A JWT Token for this session")
    field(:user, non_null(:user), description: "The user associated to this session")
  end

  @desc "An event"
  object :event do
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:local, :boolean, description: "Whether the event is local or not")
    field(:title, :string, description: "The event's title")
    field(:description, :string, description: "The event's description")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")
    field(:state, :integer, description: "State of the event")
    field(:status, :integer, description: "Status of the event")
    field(:public, :boolean, description: "Whether the event is public or not")
    # TODO replace me with picture object
    field(:thumbnail, :string, description: "A thumbnail picture for the event")
    # TODO replace me with banner
    field(:large_image, :string, description: "A large picture for the event")
    field(:publish_at, :datetime, description: "When the event was published")
    field(:address_type, :address_type, description: "The type of the event's address")
    # TODO implement these properly with an interface
    # field(:online_address, :string, description: "???")
    # field(:phone, :string, description: "")

    field(:organizer_actor, :person,
      resolve: dataloader(Actors),
      description: "The event's organizer (as a person)"
    )

    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")
    # field(:tags, list_of(:tag))
    field(:category, :category, description: "The event's category")

    field(:participants, list_of(:participant),
      resolve: &Resolvers.Event.list_participants_for_event/3,
      description: "The event's participants"
    )

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))
    # field(:physical_address, :address)

    field(:updated_at, :datetime, description: "When the event was last updated")
    field(:created_at, :datetime, description: "When the event was created")
  end

  @desc "A comment"
  object :comment do
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:content, :string)
    field(:primaryLanguage, :string)
    field(:replies, list_of(:comment))
    field(:threadLanguages, non_null(list_of(:string)))
  end

  @desc "Represents a participant to an event"
  object :participant do
    field(:event, :event,
      resolve: dataloader(Events),
      description: "The event which the actor participates in"
    )

    field(:actor, :actor, description: "The actor that participates to the event")
    field(:role, :integer, description: "The role of this actor at this event")
  end

  @desc "The list of types an address can be"
  enum :address_type do
    value(:physical, description: "The address is physical, like a postal address")
    value(:url, description: "The address is on the Web, like an URL")
    value(:phone, description: "The address is a phone number for a conference")
    value(:other, description: "The address is something else")
  end

  @desc "A category"
  object :category do
    field(:id, :id, description: "The category's ID")
    field(:description, :string, description: "The category's description")
    field(:picture, :picture, description: "The category's picture")
    field(:title, :string, description: "The category's title")
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

  @desc """
  Represents a member of a group
  """
  object :member do
    field(:parent, :group, description: "Of which the profile is member")
    field(:person, :person, description: "Which profile is member of")
    field(:role, :integer, description: "The role of this membership")
    field(:approved, :boolean, description: "Whether this membership has been approved")
  end

  @desc """
  Represents an actor's follower
  """
  object :follower do
    field(:target_actor, :actor, description: "What or who the profile follows")
    field(:actor, :actor, description: "Which profile follows")

    field(:approved, :boolean,
      description: "Whether the follow has been approved by the target actor"
    )
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
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
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
      arg(:address_type, non_null(:address_type))
      arg(:online_address, :string)
      arg(:phone, :string)
      arg(:organizer_actor_id, non_null(:integer))
      arg(:category_id, non_null(:integer))

      resolve(&Resolvers.Event.create_event/3)
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

    @desc "Create a group"
    field :create_group, :group do
      arg(:preferred_username, non_null(:string), description: "The name for the group")
      arg(:name, :string, description: "The displayed name for the group")

      arg(:creator_username, :string,
        description: "The actor's username which will be the admin (otherwise user's default one)"
      )

      resolve(&Resolvers.Group.create_group/3)
    end

    # @desc "Upload a picture"
    # field :upload_picture, :picture do
    #   arg(:file, non_null(:upload))
    #   resolve(&Resolvers.Upload.upload_picture/3)
    # end
  end
end
