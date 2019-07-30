defmodule Mobilizon.Service.ActivityPub.Converters.Address do
  @moduledoc """
  Flag converter

  This module allows to convert reports from ActivityStream format to our own internal one, and back.

  Note: Reports are named Flag in AS.
  """
  alias Mobilizon.Addresses.Address, as: AddressModel
  alias Mobilizon.Service.ActivityPub.Converter

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map()
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

    if is_nil(object["geo"]) do
      res
    else
      geo = %Geo.Point{
        coordinates: {object["geo"]["latitude"], object["geo"]["longitude"]},
        srid: 4326
      }

      Map.put(res, "geom", geo)
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @impl Converter
  @spec model_to_as(AddressModel.t()) :: map()
  def model_to_as(%AddressModel{} = _address) do
    nil
  end
end
