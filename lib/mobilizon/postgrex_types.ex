Postgrex.Types.define(
  Mobilizon.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)

defmodule Mobilizon.Ecto.DatetimeWithTimezone do
  use Timex
  require Logger

  @behaviour Ecto.Type
  def type, do: :datetimetz

  def cast(%NaiveDateTime{} = ndt), do: DateTime.from_naive(ndt, "Etc/UTC")

  def cast(%DateTime{} = dt) do
    Logger.error("casting datetime")
    Logger.error(inspect(dt))
    {:ok, DateTime.truncate(dt, :second)}
  end

  def cast(string) when is_binary(string) do
    case DateTime.from_iso8601(string) do
      {:ok, datetime, _} -> {:ok, datetime}
      {:error, _} -> :error
    end
  end

  def cast(err) do
    Logger.error("casting something")
    Logger.error(inspect(err))
    :error
  end

  def load({%DateTime{} = datetime, tzname}) when is_binary(tzname) do
    case Timex.Timezone.convert(datetime, tzname) do
      %DateTime{} = dt -> {:ok, dt}
      {:error, _} -> :error
    end
  end

  def load(_), do: :error

  def dump(%DateTime{time_zone: tzname} = datetime) do
    case Timex.Timezone.convert(datetime, "Etc/UTC") do
      %DateTime{} = dt -> {:ok, {dt, tzname}}
      {:error, _} -> :error
    end
  end

  def dump(_), do: :error
end
