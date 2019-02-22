defmodule Mobilizon.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add(:title, :string)
      add(:subtitle, :string)
      add(:short_abstract, :text)
      add(:long_abstract, :text)
      add(:language, :string)
      add(:slides_url, :string)
      add(:videos_urls, :string)
      add(:audios_urls, :string)
      add(:begins_on, :datetimetz)
      add(:ends_on, :datetimetz)
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
      add(:track_id, references(:tracks, on_delete: :delete_all))
      add(:speaker_id, references(:accounts, on_delete: :delete_all))

      timestamps()
    end
  end
end
