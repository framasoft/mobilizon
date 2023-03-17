defmodule Mobilizon.GraphQL.Schema do
  @moduledoc """
  GraphQL schema representation.
  """

  use Absinthe.Schema

  alias Mobilizon.{
    Actors,
    Addresses,
    Discussions,
    Events,
    Media,
    Reports,
    Resources,
    Todos,
    Users
  }

  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.GraphQL.{Authorization, Schema}
  alias Mobilizon.GraphQL.Middleware.{CurrentActorProvider, ErrorHandler, OperationNameLogger}
  alias Mobilizon.GraphQL.Schema.Custom
  alias Mobilizon.Storage.Repo

  @pipeline_modifier Custom.EnumTypes

  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)
  import_types(Custom.UUID)
  import_types(Custom.Point)

  import_types(Schema.ActivityType)
  import_types(Schema.UserType)
  import_types(Schema.MediaType)
  import_types(Schema.ActorInterface)
  import_types(Schema.Actors.PersonType)
  import_types(Schema.Actors.GroupType)
  import_types(Schema.Actors.ApplicationType)
  import_types(Schema.Discussions.CommentType)
  import_types(Schema.Discussions.DiscussionType)
  import_types(Schema.SearchType)
  import_types(Schema.ResourceType)
  import_types(Schema.PostType)
  import_types(Schema.Todos.TodoListType)
  import_types(Schema.Todos.TodoType)
  import_types(Schema.ConfigType)
  import_types(Schema.ReportType)
  import_types(Schema.AdminType)
  import_types(Schema.StatisticsType)
  import_types(Schema.Users.PushSubscription)
  import_types(Schema.Users.ActivitySetting)
  import_types(Schema.FollowedGroupActivityType)
  import_types(Schema.AuthApplicationType)

  @desc "A struct containing the id of the deleted object"
  object :deleted_object do
    meta(:authorize, :all)
    field(:id, :id)
  end

  @desc "A JWT and the associated user ID"
  object :login do
    meta(:authorize, :all)
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
    meta(:authorize, :user)
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
      |> Dataloader.add_source(Events, default_source)
      |> Dataloader.add_source(Discussions, Discussions.data())
      |> Dataloader.add_source(Addresses, default_source)
      |> Dataloader.add_source(Media, default_source)
      |> Dataloader.add_source(Reports, default_source)
      |> Dataloader.add_source(Resources, default_source)
      |> Dataloader.add_source(Todos, default_source)

    ctx
    |> Map.put(:loader, loader)
    |> Map.put(:authorization, Authorization)
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
    import_fields(:media_queries)
    import_fields(:report_queries)
    import_fields(:admin_queries)
    import_fields(:todo_list_queries)
    import_fields(:todo_queries)
    import_fields(:discussion_queries)
    import_fields(:resource_queries)
    import_fields(:post_queries)
    import_fields(:statistics_queries)
    import_fields(:auth_application_queries)
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
    import_fields(:media_mutations)
    import_fields(:report_mutations)
    import_fields(:admin_mutations)
    import_fields(:todo_list_mutations)
    import_fields(:todo_mutations)
    import_fields(:discussion_mutations)
    import_fields(:resource_mutations)
    import_fields(:post_mutations)
    import_fields(:actor_mutations)
    import_fields(:follower_mutations)
    import_fields(:push_mutations)
    import_fields(:activity_setting_mutations)
    import_fields(:auth_application_mutations)
  end

  @desc """
  Root subscription
  """
  subscription do
    import_fields(:person_subscriptions)
    import_fields(:discussion_subscriptions)
  end

  @spec middleware(list(module()), any(), map()) :: list(module())
  def middleware(middleware, field, %{identifier: type}) when type in [:query, :mutation] do
    [CurrentActorProvider | middleware]
    |> Enum.map(&fix_middleware_format_for_rajska/1)
    |> Rajska.add_query_authorization(field, Authorization)
    |> Rajska.add_object_authorization()
    |> List.insert_at(-1, ErrorHandler)
    |> List.insert_at(-1, OperationNameLogger)
  end

  def middleware(middleware, field, object) do
    Rajska.add_field_authorization(middleware, field, object)
  end

  defp fix_middleware_format_for_rajska({mod, config}), do: {mod, config}
  defp fix_middleware_format_for_rajska(mod), do: {mod, nil}
end
