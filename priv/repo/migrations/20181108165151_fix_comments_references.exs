defmodule Mobilizon.Repo.Migrations.FixCommentsReferences do
  @moduledoc """
  For some reason these fields references were all wrong.
  """
  use Ecto.Migration

  def up do
    drop constraint(:comments, "comments_in_reply_to_comment_id_fkey")
    drop constraint(:comments, "comments_origin_comment_id_fkey")

    alter table(:comments) do
      modify :in_reply_to_comment_id, references(:comments, on_delete: :nothing)
      modify :origin_comment_id, references(:comments, on_delete: :nothing)
    end
  end

  def down do
    drop constraint(:comments, "comments_in_reply_to_comment_id_fkey")
    drop constraint(:comments, "comments_origin_comment_id_fkey")

    alter table(:comments) do
      modify :in_reply_to_comment_id, references(:categories, on_delete: :nothing)
      modify :origin_comment_id, references(:addresses, on_delete: :delete_all)
    end
  end
end
