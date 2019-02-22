defmodule Mobilizon.Repo.Migrations.FixEventVisibility do
  use Ecto.Migration

  def up do
    Mobilizon.Events.EventVisibilityEnum.create_type()
    Mobilizon.Events.EventStatusEnum.create_type()
    Mobilizon.Events.CommentVisibilityEnum.create_type()

    alter table(:events) do
      remove(:public)
      remove(:status)
      remove(:state)
      add(:visibility, Mobilizon.Events.EventVisibilityEnum.type())
      add(:status, Mobilizon.Events.EventStatusEnum.type())
    end

    alter table(:comments) do
      add(:visibility, Mobilizon.Events.CommentVisibilityEnum.type())
    end
  end

  def down do
    alter table(:events) do
      remove(:visibility)
      remove(:status)
      add(:state, :integer, null: false, default: 0)
      add(:public, :boolean, null: false, default: false)
      add(:status, :integer, null: false, default: 0)
    end

    alter table(:comments) do
      remove(:visibility)
    end

    Mobilizon.Events.EventVisibilityEnum.drop_type()
    Mobilizon.Events.EventStatusEnum.drop_type()
    Mobilizon.Events.CommentVisibilityEnum.drop_type()
  end
end
