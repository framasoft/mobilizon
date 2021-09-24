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
          group_notifications: NotificationPendingNotificationDelay.t(),
          last_notification_sent: DateTime.t(),
          user: User.t()
        }

  @type location :: %{
          name: String.t(),
          range: integer,
          geohash: String.t()
        }

  @required_attrs [:user_id]

  @optional_attrs [
    :timezone,
    :notification_on_day,
    :notification_each_week,
    :notification_before_event,
    :notification_pending_participation,
    :notification_pending_membership,
    :group_notifications,
    :last_notification_sent
  ]

  @attrs @required_attrs ++ @optional_attrs

  @location_attrs [:name, :range, :geohash]

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

    field(:group_notifications, NotificationPendingNotificationDelay, default: :one_day)
    field(:last_notification_sent, :utc_datetime)

    embeds_one :location, Location, on_replace: :update, primary_key: false do
      field(:name, :string)
      field(:range, :integer)
      field(:geohash, :string)
    end

    belongs_to(:user, User, primary_key: true, type: :id, foreign_key: :id, define_field: false)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @attrs)
    |> cast_embed(:location, with: &location_changeset/2)
    |> validate_required(@required_attrs)
  end

  @spec location_changeset(location, map) :: Ecto.Changeset.t()
  def location_changeset(schema, params) do
    schema
    |> cast(params, @location_attrs)
  end
end
