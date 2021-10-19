defmodule Mobilizon.Service.TimezoneDetectorTest do
  @moduledoc """
  Test the timezone detector
  """

  alias Mobilizon.Service.TimezoneDetector

  use Mobilizon.DataCase

  describe "detect when no geographic data is provided" do
    test "with timezone" do
      assert "Europe/Paris" == TimezoneDetector.detect("Europe/Paris", "Europe/Paris")
    end

    test "with invalid timezone" do
      assert "Europe/Paris" == TimezoneDetector.detect("Europe/Neuilly", "Europe/Paris")
    end

    test "with default" do
      assert "Europe/Paris" == TimezoneDetector.detect(nil, "Europe/Paris")
    end
  end

  describe "with geographic data provided" do
    test "when valid with value" do
      assert "Europe/Berlin" ==
               TimezoneDetector.detect(
                 "Europe/Berlin",
                 %Geo.Point{coordinates: {4.842569, 45.751718}, properties: %{}, srid: 4326},
                 "Europe/Moscow"
               )
    end

    test "when valid with no value" do
      assert "Europe/Paris" ==
               TimezoneDetector.detect(
                 nil,
                 %Geo.Point{coordinates: {4.842569, 45.751718}, properties: %{}, srid: 4326},
                 "Europe/Moscow"
               )
    end

    test "when valid with inalid value" do
      assert "Europe/Paris" ==
               TimezoneDetector.detect(
                 "Europe/Neuilly",
                 %Geo.Point{coordinates: {4.842569, 45.751718}, properties: %{}, srid: 4326},
                 "Europe/Moscow"
               )
    end

    test "with invalid coordinates" do
      assert "Europe/Moscow" ==
               TimezoneDetector.detect(
                 nil,
                 %Geo.Point{coordinates: {0, 0}, properties: %{}, srid: 4326},
                 "Europe/Moscow"
               )
    end

    test "with no data" do
      assert "Europe/Paris" == TimezoneDetector.detect("Europe/Neuilly", nil, "Europe/Paris")
    end
  end
end
