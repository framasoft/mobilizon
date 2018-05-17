defmodule Eventos.Events.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eventos.Events.Event
  alias Eventos.Accounts.Account
  alias Eventos.Accounts.Comment

  schema "comments" do
    field :text, :string
    field :url, :string
    field :local, :boolean, default: true
    belongs_to :account, Account, [foreign_key: :account_id]
    belongs_to :event, Event, [foreign_key: :event_id]
    belongs_to :in_reply_to_comment, Comment, [foreign_key: :in_reply_to_comment_id]
    belongs_to :origin_comment, Comment, [foreign_key: :origin_comment_id]

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:url, :text, :account_id, :event_id, :in_reply_to_comment_id])
    |> validate_required([:url, :text, :account_id])
  end
end
