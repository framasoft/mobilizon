defmodule Mobilizon.Repo.Migrations.MoveFromAccountToActor do
  use Ecto.Migration

  def up do
    drop(table("event_requests"))
    drop(table("group_requests"))

    alter table("events") do
      remove(:organizer_group_id)
    end

    rename(table("members"), :account_id, to: :actor_id)

    alter table("members") do
      remove(:group_id)
      add(:parent_id, references(:accounts, on_delete: :nothing))
    end

    drop(table("groups"))
    rename(table("accounts"), to: table("actors"))
    Mobilizon.Actors.ActorType.create_type()
    rename(table("actors"), :username, to: :name)
    rename(table("actors"), :description, to: :summary)
    rename(table("actors"), :display_name, to: :preferred_username)

    alter table("actors") do
      add(:inbox_url, :string)
      add(:outbox_url, :string)
      add(:following_url, :string, null: true)
      add(:followers_url, :string, null: true)
      add(:shared_inbox_url, :string, null: false, default: "")
      add(:type, :actor_type)
      add(:manually_approves_followers, :boolean, default: false)
      modify(:name, :string, null: true)
      modify(:preferred_username, :string, null: false)
    end

    create(unique_index(:actors, [:preferred_username, :domain]))

    rename(table("events"), :organizer_account_id, to: :organizer_actor_id)

    rename(table("participants"), :account_id, to: :actor_id)

    create table("followers") do
      add(:approved, :boolean, default: false)
      add(:score, :integer, default: 1000)
      add(:actor_id, references(:actors, on_delete: :nothing))
      add(:target_actor_id, references(:actors, on_delete: :nothing))
    end

    rename(table("comments"), :account_id, to: :actor_id)

    rename(table("users"), :account_id, to: :actor_id)
  end

  def down do
    create(table("event_requests"))
    create(table("group_requests"))

    alter table("events") do
      add(:organizer_group_id, :integer)
    end

    rename(table("members"), :actor_id, to: :account_id)

    alter table("members") do
      add(:group_id, :integer)
      remove(:parent_id)
    end

    create(table("groups"))
    rename(table("actors"), to: table("accounts"))
    rename(table("accounts"), :name, to: :username)
    rename(table("accounts"), :summary, to: :description)
    rename(table("accounts"), :preferred_username, to: :display_name)

    alter table("accounts") do
      remove(:inbox_url)
      remove(:outbox_url)
      remove(:following_url)
      remove(:followers_url)
      remove(:shared_inbox_url)
      remove(:type)
      remove(:manually_approves_followers)
      modify(:username, :string, null: false)
      modify(:display_name, :string, null: true)
    end

    Mobilizon.Actors.ActorType.drop_type()

    rename(table("events"), :organizer_actor_id, to: :organizer_account_id)

    rename(table("participants"), :actor_id, to: :account_id)

    rename(table("comments"), :actor_id, to: :account_id)

    rename(table("users"), :actor_id, to: :account_id)

    drop(
      index("accounts", [:preferred_username, :domain],
        name: :actors_preferred_username_domain_index
      )
    )

    drop(table("followers"))
  end
end
