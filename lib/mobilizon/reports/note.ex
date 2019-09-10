defmodule Mobilizon.Reports.Note do
  @moduledoc """
  Report Note entity
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Reports.Report

  @timestamps_opts [type: :utc_datetime]
  @attrs [:content, :moderator_id, :report_id]

  @derive {Jason.Encoder, only: [:content]}
  schema "report_notes" do
    field(:content, :string)
    belongs_to(:moderator, Actor)
    belongs_to(:report, Report)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
  end
end
