defmodule Mobilizon.Reports.Report do
  @moduledoc """
  Represents a report entity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, ReportStatus}

  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          content: String.t(),
          status: ReportStatus.t(),
          url: String.t(),
          reported: Actor.t(),
          reporter: Actor.t(),
          manager: Actor.t(),
          event: Event.t(),
          comments: [Comment.t()],
          notes: [Note.t()]
        }

  @required_attrs [:url, :reported_id, :reporter_id]
  @optional_attrs [:content, :status, :manager_id, :event_id, :local]
  @attrs @required_attrs ++ @optional_attrs

  @timestamps_opts [type: :utc_datetime]

  @derive {Jason.Encoder, only: [:status, :url]}
  schema "reports" do
    field(:content, :string)
    field(:status, ReportStatus, default: :open)
    field(:url, :string)
    field(:local, :boolean, default: true)

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
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = report, attrs) do
    report
    |> cast(attrs, @attrs)
    |> maybe_generate_url()
    |> maybe_put_comments(attrs)
    |> validate_required(@required_attrs)
  end

  defp maybe_put_comments(%Ecto.Changeset{} = changeset, %{comments: comments}) do
    put_assoc(changeset, :comments, comments)
  end

  defp maybe_put_comments(%Ecto.Changeset{} = changeset, _), do: changeset

  @spec maybe_generate_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_generate_url(%Ecto.Changeset{} = changeset) do
    with res when res in [:error, {:data, nil}] <- fetch_field(changeset, :url),
         url <- "#{Endpoint.url()}/report/#{Ecto.UUID.generate()}" do
      put_change(changeset, :url, url)
    else
      _ -> changeset
    end
  end
end
