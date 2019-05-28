defmodule MobilizonWeb.JsonLD.ObjectView do
  use MobilizonWeb, :view

  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias MobilizonWeb.JsonLD.ObjectView
  alias MobilizonWeb.MediaProxy

  def render("event.json", %{event: %Event{} = event}) do
    # TODO: event.description is actually markdown!

    json_ld = %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.title,
      "description" => event.description,
      "performer" => %{
        "@type" =>
          if(event.organizer_actor.type == :Group, do: "PerformingGroup", else: "Person"),
        "name" => Actor.display_name(event.organizer_actor)
      },
      "location" => render_one(event.physical_address, ObjectView, "place.json", as: :address)
    }

    json_ld =
      if event.picture do
        Map.put(json_ld, "image", [
          event.picture.file.url |> MediaProxy.url()
        ])
      else
        json_ld
      end

    json_ld =
      if event.begins_on,
        do: Map.put(json_ld, "startDate", DateTime.to_iso8601(event.begins_on)),
        else: json_ld

    json_ld =
      if event.ends_on,
        do: Map.put(json_ld, "endDate", DateTime.to_iso8601(event.ends_on)),
        else: json_ld

    json_ld
  end

  def render("place.json", %{address: %Address{} = address}) do
    %{
      "@type" => "Place",
      "name" => address.description,
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => address.street,
        "addressLocality" => address.locality,
        "postalCode" => address.postal_code,
        "addressRegion" => address.region,
        "addressCountry" => address.country
      }
    }
  end

  def render("place.json", nil), do: %{}
end
