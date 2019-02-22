defmodule Mobilizon.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add(:url, :string)
      add(:text, :text)

      add(:account_id, references(:accounts, on_delete: :nothing), null: false)
      add(:event_id, references(:events, on_delete: :nothing))
      add(:in_reply_to_comment_id, references(:categories, on_delete: :nothing))
      add(:origin_comment_id, references(:addresses, on_delete: :delete_all))

      timestamps()
    end
  end
end
