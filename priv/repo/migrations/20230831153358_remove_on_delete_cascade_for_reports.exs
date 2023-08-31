defmodule Mobilizon.Storage.Repo.Migrations.RemoveOnDeleteCascadeForReports do
  use Ecto.Migration
  alias Mobilizon.Storage.Views.Instances

  def up do
    execute(Instances.drop_view())

    drop(constraint(:reports, "reports_reported_id_fkey"))
    drop(constraint(:reports, "reports_reporter_id_fkey"))
    drop(constraint(:reports, "reports_manager_id_fkey"))

    alter table(:reports) do
      modify(:reported_id, references(:actors, on_delete: :nilify_all), null: true)
      modify(:reporter_id, references(:actors, on_delete: :nilify_all), null: true)
      modify(:manager_id, references(:actors, on_delete: :nilify_all), null: true)
    end

    drop(constraint(:report_notes, "report_notes_moderator_id_fkey"))

    alter table(:report_notes) do
      modify(:moderator_id, references(:actors, on_delete: :nilify_all), null: true)
    end

    execute(Instances.create_materialized_view())
  end

  def down do
    execute(Instances.drop_view())

    drop(constraint(:reports, "reports_reported_id_fkey"))
    drop(constraint(:reports, "reports_reporter_id_fkey"))
    drop(constraint(:reports, "reports_manager_id_fkey"))

    alter table(:reports) do
      modify(:reported_id, references(:actors, on_delete: :delete_all), null: false)
      modify(:reporter_id, references(:actors, on_delete: :delete_all), null: false)
      modify(:manager_id, references(:actors, on_delete: :delete_all), null: true)
    end

    drop(constraint(:report_notes, "report_notes_moderator_id_fkey"))

    alter table(:report_notes) do
      modify(:moderator_id, references(:actors, on_delete: :delete_all), null: false)
    end

    execute(Instances.create_materialized_view())
  end
end
