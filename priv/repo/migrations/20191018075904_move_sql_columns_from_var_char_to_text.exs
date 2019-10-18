defmodule Mobilizon.Storage.Repo.Migrations.MoveSQLColumnsFromVarCharToText do
  use Ecto.Migration

  def up do
    alter table(:events) do
      modify(:title, :text, null: false)
      modify(:online_address, :text, null: true)
      modify(:phone_address, :text, null: true)
      modify(:category, :text, null: true)
      modify(:slug, :text, null: true)
    end

    alter table(:addresses) do
      modify(:description, :text, null: true)
      modify(:street, :text, null: true)
    end

    alter table(:bots) do
      modify(:source, :text, null: false)
    end

    alter table(:report_notes) do
      modify(:content, :text, null: false)
    end

    alter table(:reports) do
      modify(:content, :text, null: true)
    end

    alter table(:sessions) do
      modify(:title, :text, null: false)
      modify(:subtitle, :text, null: true)
      modify(:slides_url, :text, null: true)
      modify(:videos_urls, :text, null: true)
      modify(:audios_urls, :text, null: true)
    end

    alter table(:tracks) do
      modify(:name, :text, null: false)
    end
  end

  def down do
    alter table(:events) do
      modify(:title, :string, null: false)
      modify(:online_address, :string, null: true)
      modify(:phone_address, :string, null: true)
      modify(:category, :string, null: true)
      modify(:slug, :string, null: true)
    end

    alter table(:addresses) do
      modify(:description, :string, null: true)
      modify(:street, :string, null: true)
    end

    alter table(:bots) do
      modify(:source, :string, null: false)
    end

    alter table(:report_notes) do
      modify(:content, :string, null: false)
    end

    alter table(:reports) do
      modify(:content, :string, null: true)
    end

    alter table(:sessions) do
      modify(:title, :string, null: false)
      modify(:subtitle, :string, null: true)
      modify(:slides_url, :string, null: true)
      modify(:videos_urls, :string, null: true)
      modify(:audios_urls, :string, null: true)
    end

    alter table(:tracks) do
      modify(:name, :string, null: false)
    end
  end
end
