import EctoEnum

defenum(Mobilizon.Reports.ReportStateEnum, :report_state, [
  :open,
  :closed,
  :resolved
])

defmodule Mobilizon.Reports.Report do
  @moduledoc """
  Report entity
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.Note

  @derive {Jason.Encoder, only: [:status, :uri]}
  schema "reports" do
    field(:content, :string)
    field(:status, Mobilizon.Reports.ReportStateEnum, default: :open)
    field(:uri, :string)

    # The reported actor
    belongs_to(:reported, Actor)

    # The actor who reported
    belongs_to(:reporter, Actor)

    # The actor who last acted on this report
    belongs_to(:manager, Actor)

    # The eventual Event inside the report
    belongs_to(:event, Event)

    # The eventual Comments inside the report
    many_to_many(:comments, Comment, join_through: "reports_comments", on_replace: :delete)

    # The notes associated to the report
    has_many(:notes, Note, foreign_key: :report_id)

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:content, :status, :uri, :reported_id, :reporter_id, :manager_id, :event_id])
    |> validate_required([:content, :uri, :reported_id, :reporter_id])
  end

  def creation_changeset(report, attrs) do
    report
    |> changeset(attrs)
    |> put_assoc(:comments, attrs["comments"])
  end
end
