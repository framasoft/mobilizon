defmodule Eventos.Repo.Migrations.AddAvatarAndBannerToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :avatar_url, :string, null: true
      add :banner_url, :string, null: true
    end
  end
end
