defmodule Mobilizon.Service.DateTimeTest do
  @moduledoc """
  Test representing datetimes in defined locale
  """
  use Mobilizon.DataCase
  alias Mobilizon.Service.DateTime, as: DateTimeTools

  @datetime "2021-06-22T15:25:29.531539Z"

  describe "render a datetime to string" do
    test "standard datetime" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      assert DateTimeTools.datetime_to_string(datetime) == "Jun 22, 2021, 3:25:29 PM"
      assert DateTimeTools.datetime_to_string(datetime, "fr") == "22 juin 2021, 15:25:29"

      assert DateTimeTools.datetime_to_string(datetime, "fr", :long) ==
               "22 juin 2021 à 15:25:29 UTC"
    end

    test "non existing or loaded locale fallbacks to english" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)

      assert DateTimeTools.datetime_to_string(datetime, "es") == "Jun 22, 2021, 3:25:29 PM"
    end
  end

  describe "render a time to string" do
    test "standard time" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      assert DateTimeTools.datetime_to_time_string(datetime) == "3:25 PM"
      assert DateTimeTools.datetime_to_time_string(datetime, "fr") == "15:25"
    end

    test "non existing or loaded locale fallbacks to english" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)

      assert DateTimeTools.datetime_to_time_string(datetime, "pl") == "3:25 PM"
    end
  end

  describe "convert a datetime with a timezone" do
    test "with an existing tz" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      converted_datetime = DateTimeTools.datetime_tz_convert(datetime, "Europe/Paris")

      assert %DateTime{time_zone: "Europe/Paris", utc_offset: 3600} = converted_datetime
      assert converted_datetime |> DateTime.to_unix() == datetime |> DateTime.to_unix()
    end

    test "with an non existing tz" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      converted_datetime = DateTimeTools.datetime_tz_convert(datetime, "Planet/Mars")

      assert converted_datetime == datetime
    end
  end

  describe "gets relative time to a datetime" do
    test "standard time" do
      then = DateTime.add(DateTime.utc_now(), 3600 * -5)
      assert DateTimeTools.datetime_relative(then) == "5 hours ago"
      assert DateTimeTools.datetime_relative(then, "fr") == "il y a 5 heures"
    end

    test "non existing or loaded locale fallbacks to english" do
      then = DateTime.add(DateTime.utc_now(), 3600 * -4)

      assert DateTimeTools.datetime_relative(then, "pl") == "4 hours ago"
    end
  end

  describe "gets the first day of a week" do
    # English starts week on sunday, french on monday
    test "in the past" do
      assert DateTimeTools.calculate_first_day_of_week(~D[2021-06-25]) == ~D[2021-06-20]
    end

    test "same day" do
      assert DateTimeTools.calculate_first_day_of_week(~D[2021-06-20]) == ~D[2021-06-20]
    end

    test "locale" do
      assert DateTimeTools.calculate_first_day_of_week(~D[2021-06-20], "fr") == ~D[2021-06-14]
    end
  end

  describe "calculate next day notification" do
    test "same day" do
      assert DateTimeTools.calculate_next_day_notification(~D[2021-06-20],
               compare_to: ~U[2021-06-20 10:04:18Z]
             ) == ~U[2021-06-20 18:00:00Z]
    end

    test "tomorrow" do
      assert DateTimeTools.calculate_next_day_notification(~D[2021-06-20],
               compare_to: ~U[2021-06-20 18:04:18Z]
             ) == ~U[2021-06-21 18:00:00Z]
    end
  end

  describe "calculate next week notification" do
    test "same week" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-23 15:00:00Z],
               compare_to: ~U[2021-06-22 10:04:18Z]
             ) == nil
    end

    test "next week" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-22 15:00:00Z],
               compare_to: ~U[2021-06-14 10:04:18Z]
             ) == ~U[2021-06-20 08:00:00Z]
    end

    test "next week with custom time" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-22 15:00:00Z],
               compare_to: ~U[2021-06-14 10:04:18Z],
               notification_time: ~T[18:00:00]
             ) == ~U[2021-06-20 18:00:00Z]
    end

    test "next week with custom locale" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-22 15:00:00Z],
               compare_to: ~U[2021-06-14 10:04:18Z],
               locale: "fr"
             ) == ~U[2021-06-21 08:00:00Z]
    end

    test "same day but before time" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-21 10:00:00Z],
               compare_to: ~U[2021-06-21 07:00:00Z],
               locale: "fr"
             ) == ~U[2021-06-21 08:00:00Z]
    end

    test "same day but after time" do
      assert DateTimeTools.calculate_next_week_notification(~U[2021-06-21 15:00:00Z],
               compare_to: ~U[2021-06-21 10:04:18Z],
               locale: "fr"
             ) == nil
    end
  end

  describe "calculate next day of the week" do
    test "same week can not send a notification for next week" do
      assert DateTimeTools.next_first_day_of_week(~U[2021-06-22 15:00:00Z],
               compare_to: ~U[2021-06-21 10:04:18Z]
             ) == nil
    end

    test "next week can send a notification for next week" do
      assert DateTimeTools.next_first_day_of_week(~U[2021-06-22 15:00:00Z],
               compare_to: ~U[2021-06-15 10:04:18Z]
             ) == ~U[2021-06-20 08:00:00Z]
    end
  end

  describe "check if we're between hours" do
    test "basic" do
      refute DateTimeTools.is_between_hours?(
               compare_to_datetime: ~U[2021-06-22 15:00:00Z],
               compare_to_day: ~D[2021-06-22]
             )

      assert DateTimeTools.is_between_hours?(
               compare_to_datetime: ~U[2021-06-22 08:00:00Z],
               compare_to_day: ~D[2021-06-22]
             )

      assert DateTimeTools.is_between_hours?(
               compare_to_datetime: ~U[2021-06-22 08:01:00Z],
               compare_to_day: ~D[2021-06-22]
             )
    end

    test "with special timezone" do
      refute DateTimeTools.is_between_hours?(
               compare_to_datetime: ~U[2021-06-22 08:01:00Z],
               compare_to_day: ~D[2021-06-22],
               timezone: "Asia/Brunei"
             )

      assert DateTimeTools.is_between_hours?(
               compare_to_datetime: ~U[2021-06-22 00:01:00Z],
               compare_to_day: ~D[2021-06-22],
               timezone: "Asia/Brunei"
             )
    end
  end

  describe "check if we're between hours on right day" do
    test "basic" do
      assert DateTimeTools.is_between_hours_on_first_day?(
               compare_to_datetime: ~U[2021-06-20 08:00:00Z],
               compare_to_day: ~D[2021-06-20]
             )

      assert DateTimeTools.is_between_hours_on_first_day?(
               compare_to_datetime: ~U[2021-06-21 08:00:00Z],
               compare_to_day: ~D[2021-06-21],
               locale: "fr"
             )
    end

    test "with special timezone" do
      refute DateTimeTools.is_between_hours_on_first_day?(
               compare_to_datetime: ~U[2021-06-21 08:00:00Z],
               compare_to_day: ~D[2021-06-21],
               locale: "fr",
               timezone: "Asia/Srednekolymsk"
             )

      assert DateTimeTools.is_between_hours_on_first_day?(
               compare_to_datetime: ~U[2021-06-20 21:00:00Z],
               compare_to_day: ~D[2021-06-21],
               locale: "fr",
               timezone: "Asia/Srednekolymsk"
             )
    end
  end
end
