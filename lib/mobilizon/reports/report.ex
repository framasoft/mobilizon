defmodule Mobilizon.Reports.Report do
  @moduledoc """
  Represents a report entity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Comment, Event}
  alias Mobilizon.Reports.{Note, ReportStatus}

  @type t :: %__MODULE__{
          content: String.t(),
          status: ReportStatus.t(),
          uri: String.t(),
          reported: Actor.t(),
          reporter: Actor.t(),
          manager: Actor.t(),
          event: Event.t(),
          comments: [Comment.t()],
          notes: [Note.t()]
        }

  @required_attrs [:content, :uri, :reported_id, :reporter_id]
  @optional_attrs [:status, :manager_id, :event_id]
  @attrs @required_attrs ++ @optional_attrs

  @derive {Jason.Encoder, only: [:status, :uri]}
  schema "reports" do
    field(:content, :string)
    field(:status, ReportStatus, default: :open)
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
  @spec changeset(t | Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(report, attrs) do
    report
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end

  @doc false
  @spec creation_changeset(Report.t(), map) :: Ecto.Changeset.t()
  def creation_changeset(report, attrs) do
    report
    |> changeset(attrs)
    |> put_assoc(:comments, attrs["comments"])
  end
end
