defmodule Mobilizon.Users.Setting do
  @moduledoc """
  Module to manage users settings
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Users.{NotificationPendingNotificationDelay, User}

  @type t :: %__MODULE__{
          timezone: String.t(),
          notification_on_day: boolean,
          notification_each_week: boolean,
          notification_before_event: boolean,
          notification_pending_participation: NotificationPendingNotificationDelay.t(),
          notification_pending_membership: NotificationPendingNotificationDelay.t(),
          user: User.t()
        }

  @required_attrs [:user_id]

  @optional_attrs [
    :timezone,
    :notification_on_day,
    :notification_each_week,
    :notification_before_event,
    :notification_pending_participation,
    :notification_pending_membership
  ]

  @attrs @required_attrs ++ @optional_attrs

  @primary_key {:user_id, :id, autogenerate: false}
  schema "user_settings" do
    field(:timezone, :string)
    field(:notification_on_day, :boolean)
    field(:notification_each_week, :boolean)
    field(:notification_before_event, :boolean)

    field(:notification_pending_participation, NotificationPendingNotificationDelay,
      default: :one_day
    )

    field(:notification_pending_membership, NotificationPendingNotificationDelay,
      default: :one_day
    )

    belongs_to(:user, User, primary_key: true, type: :id, foreign_key: :id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
