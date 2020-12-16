defmodule Mobilizon.Web.JsonLD.ObjectView do
  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView

  def render("group.json", %{group: %Actor{} = group}) do
    %{
      "@context" => "http://schema.org",
      "@type" => "Organization",
      "url" => group.url,
      "name" => group.name || group.preferred_username,
      "address" => render_address(group)
    }
  end

  def render("event.json", %{event: %Event{} = event}) do
    organizer = %{
      "@type" => if(event.organizer_actor.type == :Group, do: "Organization", else: "Person"),
      "name" => Actor.display_name(event.organizer_actor)
    }

    json_ld = %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.title,
      "description" => event.description,
      # We assume for now performer == organizer
      "performer" => organizer,
      "organizer" => organizer,
      "location" => render_location(event),
      "eventStatus" =>
        if(event.status == :cancelled,
          do: "https://schema.org/EventCancelled",
          else: "https://schema.org/EventScheduled"
        ),
      "image" =>
        if(event.picture,
          do: [
            event.picture.file.url
          ],
          else: ["#{Endpoint.url()}/img/mobilizon_default_card.png"]
        )
    }

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
      "address" => render_one(address, ObjectView, "address.json", as: :address)
    }
  end

  def render("address.json", %{address: %Address{} = address}) do
    %{
      "@type" => "PostalAddress",
      "streetAddress" => address.street,
      "addressLocality" => address.locality,
      "postalCode" => address.postal_code,
      "addressRegion" => address.region,
      "addressCountry" => address.country
    }
  end

  def render("post.json", %{post: %Post{} = post}) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "name" => post.title,
      "author" => %{
        "@type" => "Organization",
        "name" => Actor.display_name(post.attributed_to)
      },
      "datePublished" => post.publish_at,
      "dateModified" => post.updated_at
    }
  end

  defp render_location(%{physical_address: %Address{} = address}),
    do: render_one(address, ObjectView, "place.json", as: :address)

  # For now the Virtual Location of an event is it's own URL,
  # but in the future it will be a special field
  defp render_location(%Event{url: event_url}) do
    %{
      "@type" => "VirtualLocation",
      "url" => event_url
    }
  end

  defp render_location(_), do: nil

  defp render_address(%{physical_address: %Address{} = address}),
    do: render_one(address, ObjectView, "address.json", as: :address)

  defp render_address(_), do: nil
end
