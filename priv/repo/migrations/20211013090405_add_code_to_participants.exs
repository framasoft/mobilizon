defmodule Mobilizon.Storage.Repo.Migrations.AddCodeToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add(:code, :string)
    end
  end
end
