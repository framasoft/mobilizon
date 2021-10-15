defmodule Mobilizon.Service.DateTime do
  @moduledoc """
  Module to represent a datetime in a given locale
  """
  alias Cldr.DateTime.Relative

  @typep to_string_format :: :short | :medium | :long | :full

  @spec datetime_to_string(DateTime.t(), String.t(), to_string_format()) :: String.t()
  def datetime_to_string(%DateTime{} = datetime, locale \\ "en", format \\ :medium) do
    Mobilizon.Cldr.DateTime.to_string!(datetime, format: format, locale: locale_or_default(locale))
  end

  @spec datetime_to_time_string(DateTime.t(), String.t(), to_string_format()) :: String.t()
  def datetime_to_time_string(%DateTime{} = datetime, locale \\ "en", format \\ :short) do
    Mobilizon.Cldr.Time.to_string!(datetime, format: format, locale: locale_or_default(locale))
  end

  @spec datetime_to_date_string(DateTime.t(), String.t(), to_string_format()) :: String.t()
  def datetime_to_date_string(%DateTime{} = datetime, locale \\ "en", format \\ :short) do
    Mobilizon.Cldr.Date.to_string!(datetime, format: format, locale: locale_or_default(locale))
  end

  @spec datetime_tz_convert(DateTime.t(), String.t() | nil) :: DateTime.t()
  def datetime_tz_convert(%DateTime{} = datetime, timezone) when is_binary(timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, datetime_with_tz} ->
        datetime_with_tz

      _ ->
        datetime
    end
  end

  def datetime_tz_convert(%DateTime{} = datetime, nil), do: datetime

  @spec datetime_relative(DateTime.t(), String.t()) :: String.t()
  def datetime_relative(%DateTime{} = datetime, locale \\ "en") do
    Relative.to_string!(datetime, Mobilizon.Cldr,
      relative_to: DateTime.utc_now(),
      locale: locale_or_default(locale)
    )
  end

  defp locale_or_default(locale) do
    if Mobilizon.Cldr.known_locale_name(locale) do
      locale
    else
      "en"
    end
  end

  @spec is_first_day_of_week(Date.t(), String.t()) :: boolean()
  defp is_first_day_of_week(%Date{} = date, locale) do
    Date.day_of_week(date) == Cldr.Calendar.first_day_for_locale(locale)
  end

  @spec calculate_first_day_of_week(Date.t(), String.t()) :: Date.t()
  def calculate_first_day_of_week(%Date{} = date, locale \\ "en") do
    if is_first_day_of_week(date, locale),
      do: date,
      else: calculate_first_day_of_week(Date.add(date, -1), locale)
  end

  @doc """
  Calculate the time when a notification should be sent, based on a daily schedule

  ## Parameters
   * `compare_to` When to compare to. Defaults to the current datetime
   * `notification_time` The time when the notification is being sent. Defaults to `~T[08:00:00]`
   * `timezone` The user's timezone. Needed to convert the time in the user's local timezone. Defaults to `"Etc/UTC"`
  """
  @spec calculate_next_day_notification(Date.t(), Keyword.t()) :: DateTime.t()
  def calculate_next_day_notification(%Date{} = day, options \\ []) do
    compare_to = Keyword.get(options, :compare_to, DateTime.utc_now())
    notification_time = Keyword.get(options, :notification_time, ~T[18:00:00])
    timezone = Keyword.get(options, :timezone, "Etc/UTC") || "Etc/UTC"

    send_at = DateTime.new!(day, notification_time, timezone)

    if DateTime.compare(send_at, compare_to) == :lt do
      day
      |> Date.add(1)
      |> DateTime.new!(notification_time, timezone)
    else
      send_at
    end
  end

  @doc """
  Calculate the time when a notification should be sent, based on a weekly schedule

  ## Parameters
   * `compare_to` When to compare to. Defaults to the current datetime
   * `notification_time` The time when the notification is being sent. Defaults to `~T[08:00:00]`
   * `timezone` The user's timezone. Needed to convert the time in the user's local timezone. Defaults to `"Etc/UTC"`
   * `locale` The user's locale. Allows to get the first day of the week to send the notification on the beginning of the week. Defaults to `"en"`.
  """
  @spec calculate_next_week_notification(DateTime.t(), Keyword.t()) :: DateTime.t() | nil
  def calculate_next_week_notification(begins_on, options \\ []) do
    # That's now, but we allow to override it for tests
    compare_to = Keyword.get(options, :compare_to, DateTime.utc_now())

    # If the event is in the future
    if DateTime.compare(begins_on, compare_to) == :gt do
      # We get the day of the scheduled notification next week
      notification_date = appropriate_first_day_of_week(begins_on, options)

      if is_nil(notification_date) do
        nil
      else
        # This is the datetime when the notification should be sent
        if DateTime.compare(notification_date, compare_to) == :gt do
          notification_date
        else
          nil
        end
      end
    else
      # In the past, don't send anything
      nil
    end
  end

  @spec next_first_day_of_week(DateTime.t(), Keyword.t()) :: Date.t() | nil
  def next_first_day_of_week(%DateTime{} = datetime, options) do
    locale = Keyword.get(options, :locale, "en")
    compare_to = Keyword.get(options, :compare_to, DateTime.utc_now())

    next_first_day_of_week =
      compare_to
      |> DateTime.to_date()
      |> calculate_first_day_of_week(locale)
      |> Date.add(7)
      |> build_notification_datetime(options)

    if next_first_day_of_week != nil && DateTime.compare(datetime, next_first_day_of_week) == :gt do
      next_first_day_of_week
    else
      nil
    end
  end

  @spec appropriate_first_day_of_week(DateTime.t(), keyword) :: DateTime.t() | nil
  defp appropriate_first_day_of_week(%DateTime{} = datetime, options) do
    locale = Keyword.get(options, :locale, "en")
    timezone = Keyword.get(options, :timezone, "Etc/UTC")

    local_datetime = datetime_tz_convert(datetime, timezone)

    first_day = local_datetime |> DateTime.to_date() |> calculate_first_day_of_week(locale)
    first_datetime = build_notification_datetime(first_day, options)

    if DateTime.compare(local_datetime, first_datetime) == :gt do
      first_datetime
    else
      local_datetime
      |> next_first_day_of_week(options)
      |> build_notification_datetime(options)
    end
  end

  @spec build_notification_datetime(Date.t(), Keyword.t()) :: DateTime.t()
  @spec build_notification_datetime(nil, Keyword.t()) :: nil
  defp build_notification_datetime(nil, _options), do: nil

  defp build_notification_datetime(
         %Date{} = date,
         options
       ) do
    notification_time = Keyword.get(options, :notification_time, ~T[08:00:00])
    timezone = Keyword.get(options, :timezone, "Etc/UTC")
    DateTime.new!(date, notification_time, timezone)
  end

  @start_time ~T[08:00:00]
  @end_time ~T[09:00:00]

  @spec is_between_hours?(Keyword.t()) :: boolean()
  def is_between_hours?(options \\ []) when is_list(options) do
    compare_to_day = Keyword.get(options, :compare_to_day, Date.utc_today())
    compare_to = Keyword.get(options, :compare_to_datetime, DateTime.utc_now())
    start_time = Keyword.get(options, :start_time, @start_time)
    timezone = Keyword.get(options, :timezone, "Etc/UTC")
    end_time = Keyword.get(options, :end_time, @end_time)

    DateTime.compare(compare_to, DateTime.new!(compare_to_day, start_time, timezone)) in [
      :gt,
      :eq
    ] &&
      DateTime.compare(
        compare_to,
        DateTime.new!(compare_to_day, end_time, timezone)
      ) == :lt
  end

  @spec is_between_hours_on_first_day?(Keyword.t()) :: boolean()
  def is_between_hours_on_first_day?(options) when is_list(options) do
    compare_to_day = Keyword.get(options, :compare_to_day, Date.utc_today())
    locale = Keyword.get(options, :locale, "en")

    is_first_day_of_week(compare_to_day, locale) && is_between_hours?(options)
  end

  @spec is_delay_ok_since_last_notification_sent?(DateTime.t()) :: boolean()
  def is_delay_ok_since_last_notification_sent?(%DateTime{} = last_notification_sent) do
    DateTime.compare(DateTime.add(last_notification_sent, 3_600), DateTime.utc_now()) ==
      :lt
  end

  @spec is_same_day?(DateTime.t(), DateTime.t()) :: boolean()
  def is_same_day?(%DateTime{} = one, %DateTime{} = two) do
    DateTime.to_date(one) == DateTime.to_date(two)
  end
end
