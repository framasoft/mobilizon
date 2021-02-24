defmodule Mobilizon.GraphQL.Schema.ActivityType do
  @moduledoc """
  Schema representation for Activity
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource

  enum :activity_type do
    value(:event, description: "Activities concerning events")
    value(:post, description: "Activities concerning posts")
    value(:discussion, description: "Activities concerning discussions")
    value(:resource, description: "Activities concerning resources")
    value(:group, description: "Activities concerning group settings")
    value(:member, description: "Activities concerning members")
  end

  object :activity_param_item do
    field(:key, :string)
    field(:value, :string)
  end

  interface :activity_object do
    field(:id, :id)

    resolve_type(fn
      %Event{}, _ ->
        :event

      %Post{}, _ ->
        :post

      %Actor{type: "Group"}, _ ->
        :group

      %Member{}, _ ->
        :member

      %Resource{}, _ ->
        :resource

      %Discussion{}, _ ->
        :discussion

      %Actor{type: :Group}, _ ->
        :group

      _, _ ->
        nil
    end)
  end

  @desc """
  A paginated list of activity items
  """
  object :paginated_activity_list do
    field(:elements, list_of(:activity), description: "A list of activities")
    field(:total, :integer, description: "The total number of elements in the list")
  end

  object :activity do
    field(:id, :id, description: "The activity item ID")
    field(:inserted_at, :datetime, description: "When was the activity inserted")
    field(:priority, :integer)
    field(:type, :activity_type)
    field(:subject, :string)
    field(:subject_params, list_of(:activity_param_item))
    field(:message, :string)
    field(:message_params, list_of(:activity_param_item))
    field(:object, :activity_object)
    field(:author, :actor)
    field(:group, :group)
  end
end
