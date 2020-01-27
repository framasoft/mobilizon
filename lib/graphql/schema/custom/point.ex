defmodule Mobilizon.GraphQL.Schema.Custom.Point do
  @moduledoc """
  The geom scalar type allows Geo.PostGIS.Geometry strings to be passed in and out.
  Requires `{:geo, "~> 3.0"},` package: https://github.com/elixir-ecto/ecto
  """
  use Absinthe.Schema.Notation

  scalar :point, name: "Point" do
    description("""
    The `Point` scalar type represents Point geographic information compliant string data, 
    represented as floats separated by a semi-colon. The geodetic system is WGS 84
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    with [_, _] = lonlat <- String.split(value, ";", trim: true),
         [{lon, ""}, {lat, ""}] <- Enum.map(lonlat, &Float.parse(&1)) do
      {:ok, %Geo.Point{coordinates: {lon, lat}, srid: 4326}}
    else
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(%Geo.Point{coordinates: {lon, lat}, srid: 4326}), do: "#{lon};#{lat}"
end
