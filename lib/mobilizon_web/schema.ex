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

  import_types(MobilizonWeb.Schema.UserType)
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
    @desc "Search through events, persons and groups"
    field :search, list_of(:search_result) do
      arg(:search, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Search.search_events_and_actors/3)
    end

    import_fields(:user_queries)
    import_fields(:person_queries)
    import_fields(:group_queries)
    import_fields(:event_queries)
    import_fields(:participant_queries)
    import_fields(:category_queries)
    import_fields(:tag_queries)
  end

  @desc """
  Root Mutation
  """
  mutation do
    import_fields(:user_mutations)
    import_fields(:person_mutations)
    import_fields(:group_mutations)
    import_fields(:event_mutations)
    import_fields(:category_mutations)
    import_fields(:comment_mutations)
    import_fields(:participant_mutations)

    # @desc "Upload a picture"
    # field :upload_picture, :picture do
    #   arg(:file, non_null(:upload))
    #   resolve(&Resolvers.Upload.upload_picture/3)
    # end
  end
end
