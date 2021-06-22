defmodule Mobilizon.Service.DateTimeTest do
  @moduledoc """
  Test representing datetimes in defined locale
  """
  use Mobilizon.DataCase
  alias Mobilizon.Service.DateTime, as: DateTimeRenderer

  @datetime "2021-06-22T15:25:29.531539Z"

  describe "render a datetime to string" do
    test "standard datetime" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      assert DateTimeRenderer.datetime_to_string(datetime) == "Jun 22, 2021, 3:25:29 PM"
      assert DateTimeRenderer.datetime_to_string(datetime, "fr") == "22 juin 2021, 15:25:29"

      assert DateTimeRenderer.datetime_to_string(datetime, "fr", :long) ==
               "22 juin 2021 à 15:25:29 UTC"
    end

    test "non existing or loaded locale fallbacks to english" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)

      assert DateTimeRenderer.datetime_to_string(datetime, "es") == "Jun 22, 2021, 3:25:29 PM"
    end
  end

  describe "render a time to string" do
    test "standard time" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      assert DateTimeRenderer.datetime_to_time_string(datetime) == "3:25 PM"
      assert DateTimeRenderer.datetime_to_time_string(datetime, "fr") == "15:25"
    end

    test "non existing or loaded locale fallbacks to english" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)

      assert DateTimeRenderer.datetime_to_time_string(datetime, "pl") == "3:25 PM"
    end
  end

  describe "convert a datetime with a timezone" do
    test "with an existing tz" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      converted_datetime = DateTimeRenderer.datetime_tz_convert(datetime, "Europe/Paris")

      assert %DateTime{time_zone: "Europe/Paris", utc_offset: 3600} = converted_datetime
      assert converted_datetime |> DateTime.to_unix() == datetime |> DateTime.to_unix()
    end

    test "with an non existing tz" do
      {:ok, datetime, _} = DateTime.from_iso8601(@datetime)
      converted_datetime = DateTimeRenderer.datetime_tz_convert(datetime, "Planet/Mars")

      assert converted_datetime == datetime
    end
  end

  describe "gets relative time to a datetime" do
    test "standard time" do
      then = DateTime.add(DateTime.utc_now(), 3600 * -5)
      assert DateTimeRenderer.datetime_relative(then) == "5 hours ago"
      assert DateTimeRenderer.datetime_relative(then, "fr") == "il y a 5 heures"
    end

    test "non existing or loaded locale fallbacks to english" do
      then = DateTime.add(DateTime.utc_now(), 3600 * -4)

      assert DateTimeRenderer.datetime_relative(then, "pl") == "4 hours ago"
    end
  end
end
