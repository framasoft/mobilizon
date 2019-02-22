defmodule Mobilizon.Repo.Migrations.AddAvatarAndBannerToActor do
  use Ecto.Migration

  def up do
    alter table(:actors) do
      add(:avatar_url, :string)
      add(:banner_url, :string)
    end
  end

  def down do
    alter table(:actors) do
      remove(:avatar_url)
      remove(:banner_url)
    end
  end
end
