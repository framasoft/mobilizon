defmodule Mobilizon.Users.PushSubscription do
  @moduledoc """
  Represents informations about a push subscription for a specific user
  """
  use Ecto.Schema
  alias Mobilizon.Users.User
  import Ecto.Changeset

  @type t :: %__MODULE__{
          digest: String.t(),
          user: User.t(),
          endpoint: String.t(),
          auth: String.t(),
          p256dh: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_push_subscriptions" do
    field(:digest, :string)
    belongs_to(:user, User)
    field(:endpoint, :string)
    field(:auth, :string)
    field(:p256dh, :string)
    timestamps()
  end

  @doc false
  def changeset(push_subscription, attrs) do
    push_subscription
    |> cast(attrs, [:user_id, :endpoint, :auth, :p256dh])
    |> put_change(:digest, compute_digest(attrs))
    |> validate_required([:digest, :user_id, :endpoint, :auth, :p256dh])
    |> unique_constraint([:digest, :user_id], name: :user_push_subscriptions_user_id_digest_index)
  end

  defp compute_digest(attrs) do
    data =
      Jason.encode!(%{endpoint: attrs.endpoint, keys: %{auth: attrs.auth, p256dh: attrs.p256dh}})

    :sha256
    |> :crypto.hash(data)
    |> Base.encode16()
  end
end
