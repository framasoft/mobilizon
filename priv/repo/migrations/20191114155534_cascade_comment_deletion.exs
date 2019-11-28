defmodule Mobilizon.Storage.Repo.Migrations.CascadeCommentDeletion do
  use Ecto.Migration

  def up do
    drop(constraint(:comments, "comments_in_reply_to_comment_id_fkey"))
    drop(constraint(:comments, "comments_origin_comment_id_fkey"))

    alter table(:comments) do
      modify(:in_reply_to_comment_id, references(:comments, on_delete: :nilify_all))
      modify(:origin_comment_id, references(:comments, on_delete: :nilify_all))
    end
  end

  def down do
    drop(constraint(:comments, "comments_in_reply_to_comment_id_fkey"))
    drop(constraint(:comments, "comments_origin_comment_id_fkey"))

    alter table(:comments) do
      modify(:in_reply_to_comment_id, references(:comments, on_delete: :nothing))
      modify(:origin_comment_id, references(:comments, on_delete: :nothing))
    end
  end
end
