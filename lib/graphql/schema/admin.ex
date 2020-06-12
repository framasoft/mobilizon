defmodule Mobilizon.GraphQL.Schema.AdminType do
  @moduledoc """
  Schema representation for ActionLog.
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}

  alias Mobilizon.GraphQL.Resolvers.Admin

  @desc "An action log"
  object :action_log do
    field(:id, :id, description: "Internal ID for this comment")
    field(:actor, :actor, description: "The actor that acted")
    field(:object, :action_log_object, description: "The object that was acted upon")
    field(:action, :action_log_action, description: "The action that was done")
    field(:inserted_at, :datetime, description: "The time when the action was performed")
  end

  enum :action_log_action do
    value(:report_update_closed)
    value(:report_update_opened)
    value(:report_update_resolved)
    value(:note_creation)
    value(:note_deletion)
    value(:event_deletion)
    value(:comment_deletion)
    value(:event_update)
    value(:actor_suspension)
    value(:actor_unsuspension)
  end

  @desc "The objects that can be in an action log"
  interface :action_log_object do
    field(:id, :id, description: "Internal ID for this object")

    resolve_type(fn
      %Report{}, _ ->
        :report

      %Note{}, _ ->
        :report_note

      %Event{}, _ ->
        :event

      %Comment{}, _ ->
        :comment

      %Actor{type: "Person"}, _ ->
        :person

      _, _ ->
        nil
    end)
  end

  object :dashboard do
    field(:last_public_event_published, :event, description: "Last public event publish")
    field(:number_of_users, :integer, description: "The number of local users")
    field(:number_of_events, :integer, description: "The number of local events")
    field(:number_of_comments, :integer, description: "The number of local comments")
    field(:number_of_reports, :integer, description: "The number of current opened reports")
  end

  object :admin_settings do
    field(:instance_name, :string)
    field(:instance_description, :string)
    field(:instance_terms, :string)
    field(:instance_terms_type, :instance_terms_type)
    field(:instance_terms_url, :string)
    field(:registrations_open, :boolean)
  end

  enum :instance_terms_type do
    value(:url, as: "URL")
    value(:default, as: "DEFAULT")
    value(:custom, as: "CUSTOM")
  end

  object :admin_queries do
    @desc "Get the list of action logs"
    field :action_logs, type: list_of(:action_log) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Admin.list_action_logs/3)
    end

    field :dashboard, type: :dashboard do
      resolve(&Admin.get_dashboard/3)
    end

    field :admin_settings, type: :admin_settings do
      resolve(&Admin.get_settings/3)
    end

    field :relay_followers, type: :paginated_follower_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Admin.list_relay_followers/3)
    end

    field :relay_followings, type: :paginated_follower_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      arg(:order_by, :string, default_value: :updated_at)
      arg(:direction, :string, default_value: :desc)
      resolve(&Admin.list_relay_followings/3)
    end
  end

  object :admin_mutations do
    @desc "Add a relay subscription"
    field :add_relay, type: :follower do
      arg(:address, non_null(:string))

      resolve(&Admin.create_relay/3)
    end

    @desc "Delete a relay subscription"
    field :remove_relay, type: :follower do
      arg(:address, non_null(:string))

      resolve(&Admin.remove_relay/3)
    end

    @desc "Accept a relay subscription"
    field :accept_relay, type: :follower do
      arg(:address, non_null(:string))

      resolve(&Admin.accept_subscription/3)
    end

    @desc "Reject a relay subscription"
    field :reject_relay, type: :follower do
      arg(:address, non_null(:string))

      resolve(&Admin.reject_subscription/3)
    end

    field :save_admin_settings, type: :admin_settings do
      arg(:instance_name, :string)
      arg(:instance_description, :string)
      arg(:instance_terms, :string)
      arg(:instance_terms_type, :instance_terms_type)
      arg(:instance_terms_url, :string)
      arg(:registrations_open, :boolean)

      resolve(&Admin.save_settings/3)
    end
  end
end
