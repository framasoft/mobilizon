defmodule Mobilizon.Repo.Migrations.CreateReports do
  use Ecto.Migration
  alias Mobilizon.Reports.ReportStatus

  def up do
    ReportStatus.create_type()

    create table(:reports) do
      add(:content, :string)
      add(:status, ReportStatus.type(), default: "open", null: false)
      add(:uri, :string, null: false)

      add(:reported_id, references(:actors, on_delete: :delete_all), null: false)
      add(:reporter_id, references(:actors, on_delete: :delete_all), null: false)
      add(:manager_id, references(:actors, on_delete: :delete_all), null: true)
      add(:event_id, references(:events, on_delete: :delete_all), null: true)

      timestamps()
    end

    create table(:reports_comments, primary_key: false) do
      add(:report_id, references(:reports, on_delete: :delete_all), null: false)
      add(:comment_id, references(:comments, on_delete: :delete_all), null: false)
    end
  end

  def down do
    drop(table(:reports_comments))
    drop(table(:reports))

    ReportStatus.drop_type()
  end
end
