defmodule Mobilizon.Storage.Repo.Migrations.AddActivityTable do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add(:priority, :integer, null: false)
      add(:type, :string, null: false)
      add(:author_id, references(:actors, on_delete: :delete_all), null: false)
      add(:group_id, references(:actors, on_delete: :delete_all), null: false)
      add(:subject, :string, null: false)
      add(:subject_params, :map, null: false)
      add(:message, :string)
      add(:message_params, :map)
      add(:object_type, :string)
      add(:object_id, :string)

      timestamps(updated_at: false, type: :utc_datetime)
    end
  end
end
