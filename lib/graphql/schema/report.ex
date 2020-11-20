defmodule Mobilizon.GraphQL.Schema.ReportType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.GraphQL.Resolvers.Report
  alias Mobilizon.Reports

  @desc "A report object"
  object :report do
    interfaces([:action_log_object])
    field(:id, :id, description: "The internal ID of the report")
    field(:content, :string, description: "The comment the reporter added about this report")
    field(:status, :report_status, description: "Whether the report is still active")
    field(:uri, :string, description: "The URI of the report")
    field(:reported, :actor, description: "The actor that is being reported")
    field(:reporter, :actor, description: "The actor that created the report")
    field(:event, :event, description: "The event that is being reported")
    field(:comments, list_of(:comment), description: "The comments that are reported")

    field(:notes, list_of(:report_note),
      description: "The notes made on the event",
      resolve: dataloader(Reports)
    )

    field(:inserted_at, :datetime, description: "When the report was created")
    field(:updated_at, :datetime, description: "When the report was updated")
  end

  @desc "A report note object"
  object :report_note do
    interfaces([:action_log_object])
    field(:id, :id, description: "The internal ID of the report note")
    field(:content, :string, description: "The content of the note")

    field(:moderator, :actor,
      description: "The moderator who added the note",
      resolve: dataloader(Reports)
    )

    field(:report, :report, description: "The report on which this note is added")
    field(:inserted_at, :datetime, description: "When the report note was created")
  end

  @desc "The list of possible statuses for a report object"
  enum :report_status do
    value(:open, description: "The report has been opened")
    value(:closed, description: "The report has been closed")
    value(:resolved, description: "The report has been marked as resolved")
  end

  object :report_queries do
    @desc "Get all reports"
    field :reports, list_of(:report) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the reports participations list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of reports per page")
      arg(:status, :report_status, default_value: :open, description: "Filter reports by status")
      resolve(&Report.list_reports/3)
    end

    @desc "Get a report by id"
    field :report, :report do
      arg(:id, non_null(:id), description: "The report ID")
      resolve(&Report.get_report/3)
    end
  end

  object :report_mutations do
    @desc "Create a report"
    field :create_report, type: :report do
      arg(:content, :string, description: "The message sent with the report")
      arg(:reported_id, non_null(:id), description: "The actor's ID that is being reported")
      arg(:event_id, :id, default_value: nil, description: "The event ID that is being reported")

      arg(:comments_ids, list_of(:id),
        default_value: [],
        description: "The comment ID that is being reported"
      )

      arg(:forward, :boolean,
        default_value: false,
        description:
          "Whether to forward the report to the original instance if the content is remote"
      )

      resolve(&Report.create_report/3)
    end

    @desc "Update a report"
    field :update_report_status, type: :report do
      arg(:report_id, non_null(:id), description: "The report's ID")
      arg(:status, non_null(:report_status), description: "The report's new status")
      resolve(&Report.update_report/3)
    end

    @desc "Create a note on a report"
    field :create_report_note, type: :report_note do
      arg(:content, :string, description: "The note's content")
      arg(:report_id, non_null(:id), description: "The report's ID")
      resolve(&Report.create_report_note/3)
    end

    @desc "Delete a note on a report"
    field :delete_report_note, type: :deleted_object do
      arg(:note_id, non_null(:id), description: "The note's ID")
      resolve(&Report.delete_report_note/3)
    end
  end
end
