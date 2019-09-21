defmodule Mobilizon.Reports.Note do
  @moduledoc """
  Represents a note entity.
  """

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.Report

  @required_attrs [:content, :moderator_id, :report_id]
  @attrs @required_attrs

  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          content: String.t(),
          report: Report.t(),
          moderator: Actor.t()
        }

  @derive {Jason.Encoder, only: [:content]}
  schema "report_notes" do
    field(:content, :string)

    belongs_to(:report, Report)
    belongs_to(:moderator, Actor)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = note, attrs) do
    note
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
