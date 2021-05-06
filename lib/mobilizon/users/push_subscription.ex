defmodule Mobilizon.Users.PushSubscription do
  use Ecto.Schema
  alias Mobilizon.Users.User
  import Ecto.Changeset

  schema "user_push_subscriptions" do
    field(:digest, :string)
    belongs_to(:user, User)

    embeds_one :data, Data, on_replace: :delete do
      field(:endpoint, :string)

      embeds_one :keys, Keys, on_replace: :delete do
        field(:auth, :string)
        field(:p256dh, :string)
      end
    end

    timestamps()
  end

  @doc false
  def changeset(push_subscription, attrs) do
    push_subscription
    |> cast(attrs, [:user_id])
    |> cast_embed(:data, with: &cast_data/2)
    |> put_change(:digest, compute_digest(attrs.data))
    |> validate_required([:digest, :user_id, :data])
  end

  defp cast_data(schema, attrs) do
    schema
    |> cast(attrs, [:endpoint])
    |> cast_embed(:keys, with: &cast_keys/2)
    |> validate_required([:endpoint, :keys])
  end

  defp cast_keys(schema, attrs) do
    schema
    |> cast(attrs, [:auth, :p256dh])
    |> validate_required([:auth, :p256dh])
  end

  defp compute_digest(data) do
    :sha256
    |> :crypto.hash(data)
    |> Base.encode16()
  end
end
