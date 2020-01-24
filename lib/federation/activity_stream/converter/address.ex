defmodule Mobilizon.Federation.ActivityStream.Converter.Address do
  @moduledoc """
  Address converter.

  This module allows to convert reports from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Addresses.Address, as: AddressModel

  alias Mobilizon.Federation.ActivityStream.Converter

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(object) do
    res = %{
      "description" => object["name"],
      "url" => object["url"]
    }

    res =
      if is_nil(object["address"]) do
        res
      else
        Map.merge(res, %{
          "country" => object["address"]["addressCountry"],
          "postal_code" => object["address"]["postalCode"],
          "region" => object["address"]["addressRegion"],
          "street" => object["address"]["streetAddress"],
          "locality" => object["address"]["addressLocality"]
        })
      end

    if is_nil(object["latitude"]) or is_nil(object["longitude"]) do
      res
    else
      geo = %Geo.Point{
        coordinates: {object["latitude"], object["longitude"]},
        srid: 4326
      }

      Map.put(res, "geom", geo)
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(AddressModel.t()) :: map
  def model_to_as(%AddressModel{} = address) do
    res = %{
      "type" => "Place",
      "name" => address.description,
      "id" => address.url,
      "address" => %{
        "type" => "PostalAddress",
        "streetAddress" => address.street,
        "postalCode" => address.postal_code,
        "addressLocality" => address.locality,
        "addressRegion" => address.region,
        "addressCountry" => address.country
      }
    }

    if is_nil(address.geom) do
      res
    else
      res
      |> Map.put("latitude", address.geom.coordinates |> elem(0))
      |> Map.put("longitude", address.geom.coordinates |> elem(1))
    end
  end
end
