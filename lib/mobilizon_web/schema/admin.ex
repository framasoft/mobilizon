defmodule MobilizonWeb.Schema.AdminType do
  @moduledoc """
  Schema representation for ActionLog
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers.Admin
  alias Mobilizon.Reports.{Report, Note}

  @desc "An action log"
  object :action_log do
    field(:id, :id, description: "Internal ID for this comment")
    field(:actor, :actor, description: "The actor that acted")
    field(:object, :action_log_object, description: "The object that was acted upon")
    field(:action, :string, description: "The action that was done")
  end

  @desc "The objects that can be in an action log"
  interface :action_log_object do
    field(:id, :id, description: "Internal ID for this object")

    resolve_type(fn
      %Report{}, _ ->
        :report

      %Note{}, _ ->
        :report_note

      _, _ ->
        nil
    end)
  end

  object :admin_queries do
    @desc "Get the list of action logs"
    field :action_logs, type: list_of(:action_log) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Admin.list_action_logs/3)
    end
  end
end
