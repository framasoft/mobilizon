defmodule Mobilizon.Repo.Migrations.CreateReportNotes do
  use Ecto.Migration

  def change do
    create table(:report_notes) do
      add(:content, :string, null: false)
      add(:moderator_id, references(:actors, on_delete: :delete_all), null: false)
      add(:report_id, references(:reports, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
