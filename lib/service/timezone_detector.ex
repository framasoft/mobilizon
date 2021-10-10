defmodule Mobilizon.Service.TimezoneDetector do
  @moduledoc """
  Detect the timezone from a point
  """

  @type detectable :: Geo.Point.t() | Geo.PointZ.t() | {float() | float()}

  @doc """
  Detect the most appropriate timezone from a value, a geographic set of coordinates and a fallback
  """
  @spec detect(String.t() | nil, detectable(), String.t()) :: String.t()
  def detect(nil, geo, fallback) do
    case TzWorld.timezone_at(geo) do
      {:ok, timezone} ->
        timezone

      {:error, :time_zone_not_found} ->
        fallback
    end
  end

  def detect(timezone, geo, fallback) do
    if Tzdata.zone_exists?(timezone) do
      timezone
    else
      detect(nil, geo, fallback)
    end
  end

  @spec detect(String.t() | nil, String.t()) :: String.t()
  def detect(nil, fallback), do: fallback

  def detect(timezone, fallback) do
    if Tzdata.zone_exists?(timezone) do
      timezone
    else
      fallback
    end
  end
end
