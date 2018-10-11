defmodule MobilizonWeb.AddressView do
  @moduledoc """
  View for addresses
  """

  use MobilizonWeb, :view
  alias MobilizonWeb.AddressView

  def render("index.json", %{addresses: addresses}) do
    %{data: render_many(addresses, AddressView, "address.json")}
  end

  def render("show.json", %{address: address}) do
    %{data: render_one(address, AddressView, "address.json")}
  end

  def render("address.json", %{address: address}) do
    %{
      id: address.id,
      description: address.description,
      floor: address.floor,
      addressCountry: address.addressCountry,
      addressLocality: address.addressLocality,
      addressRegion: address.addressRegion,
      postalCode: address.postalCode,
      streetAddress: address.streetAddress,
      geom: render_one(address.geom, AddressView, "geom.json")
    }
  end

  def render("geom.json", %{address: %Geo.Point{} = point}) do
    [lat, lon] = Tuple.to_list(point.coordinates)

    %{
      type: "point",
      data: %{
        latitude: lat,
        longitude: lon
      }
    }
  end
end
