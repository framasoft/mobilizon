defmodule Mobilizon.Repo.Migrations.CreateExports do
  use Ecto.Migration

  def change do
    create table(:exports) do
      add(:file_path, :string)
      add(:file_size, :integer)
      add(:file_name, :string)
      add(:type, :string)
      add(:reference, :string)
      add(:format, :string)

      timestamps()
    end

    create(unique_index(:exports, [:file_path]))
  end
end
