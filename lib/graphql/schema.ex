defmodule Mobilizon.GraphQL.Schema do
  @moduledoc """
  GraphQL schema representation.
  """

  use Absinthe.Schema

  alias Mobilizon.{Actors, Addresses, Events, Media, Reports, Users}
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.{Comment, Event, Participant}
  alias Mobilizon.GraphQL.Schema
  alias Mobilizon.Storage.Repo

  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)
  import_types(Schema.Custom.UUID)
  import_types(Schema.Custom.Point)

  import_types(Schema.UserType)
  import_types(Schema.PictureType)
  import_types(Schema.ActorInterface)
  import_types(Schema.Actors.PersonType)
  import_types(Schema.Actors.GroupType)
  import_types(Schema.Actors.ApplicationType)
  import_types(Schema.CommentType)
  import_types(Schema.SearchType)
  import_types(Schema.ConfigType)
  import_types(Schema.ReportType)
  import_types(Schema.AdminType)

  @desc "A struct containing the id of the deleted object"
  object :deleted_object do
    field(:id, :id)
  end

  @desc "A JWT and the associated user ID"
  object :login do
    field(:access_token, non_null(:string), description: "A JWT Token for this session")

    field(:refresh_token, non_null(:string),
      description: "A JWT Token to refresh the access token"
    )

    field(:user, non_null(:user), description: "The user associated to this session")
  end

  @desc """
  Represents a notification for an user
  """
  object :notification do
    field(:id, :id, description: "The notification ID")
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

  def context(ctx) do
    default_query = fn queryable, _params -> queryable end
    default_source = Dataloader.Ecto.new(Repo, query: default_query)

    loader =
      Dataloader.new()
      |> Dataloader.add_source(Actors, default_source)
      |> Dataloader.add_source(Users, default_source)
      |> Dataloader.add_source(Events, Events.data())
      |> Dataloader.add_source(Addresses, default_source)
      |> Dataloader.add_source(Media, default_source)
      |> Dataloader.add_source(Reports, default_source)

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  @desc """
  Root Query
  """
  query do
    import_fields(:search_queries)
    import_fields(:user_queries)
    import_fields(:person_queries)
    import_fields(:group_queries)
    import_fields(:event_queries)
    import_fields(:comment_queries)
    import_fields(:tag_queries)
    import_fields(:address_queries)
    import_fields(:config_queries)
    import_fields(:picture_queries)
    import_fields(:report_queries)
    import_fields(:admin_queries)
  end

  @desc """
  Root Mutation
  """
  mutation do
    import_fields(:user_mutations)
    import_fields(:person_mutations)
    import_fields(:group_mutations)
    import_fields(:event_mutations)
    import_fields(:comment_mutations)
    import_fields(:participant_mutations)
    import_fields(:member_mutations)
    import_fields(:feed_token_mutations)
    import_fields(:picture_mutations)
    import_fields(:report_mutations)
    import_fields(:admin_mutations)
  end

  @desc """
  Root subscription
  """
  subscription do
    import_fields(:person_subscriptions)
  end
end
