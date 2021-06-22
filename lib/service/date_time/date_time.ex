defmodule Mobilizon.Service.DateTime do
  @moduledoc """
  Module to represent a datetime in a given locale
  """
  alias Cldr.DateTime.Relative

  def datetime_to_string(%DateTime{} = datetime, locale \\ "en", format \\ :medium) do
    Mobilizon.Cldr.DateTime.to_string!(datetime, format: format, locale: locale_or_default(locale))
  end

  def datetime_to_time_string(%DateTime{} = datetime, locale \\ "en", format \\ :short) do
    Mobilizon.Cldr.Time.to_string!(datetime, format: format, locale: locale_or_default(locale))
  end

  @spec datetime_tz_convert(DateTime.t(), String.t()) :: DateTime.t()
  def datetime_tz_convert(%DateTime{} = datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, datetime_with_user_tz} ->
        datetime_with_user_tz

      _ ->
        datetime
    end
  end

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
end
