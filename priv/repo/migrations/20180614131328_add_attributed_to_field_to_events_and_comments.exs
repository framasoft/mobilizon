defmodule Mobilizon.Repo.Migrations.AddAttributedToFieldToEventsAndComments do
  use Ecto.Migration

  def up do
    alter table(:events) do
      add(:attributed_to_id, references(:actors, on_delete: :nothing))
    end

    alter table(:comments) do
      add(:attributed_to_id, references(:actors, on_delete: :nothing))
    end
  end

  def down do
    alter table(:events) do
      remove(:attributed_to_id)
    end

    alter table(:comments) do
      remove(:attributed_to_id)
    end
  end
end
