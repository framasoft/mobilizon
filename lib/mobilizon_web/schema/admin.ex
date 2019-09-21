defmodule MobilizonWeb.Schema.AdminType do
  @moduledoc """
  Schema representation for ActionLog
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers.Admin
  alias Mobilizon.Reports.{Report, Note}
  alias Mobilizon.Events.Event

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
    value(:event_update)
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
  end
end
