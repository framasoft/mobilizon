defmodule Mobilizon.Web.JsonLD.ObjectView do
  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.{Event, EventOptions, Participant, ParticipantRole}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.Router.Helpers, as: Routes

  import Mobilizon.Service.Metadata.Utils,
    only: [process_description: 3]

  @spec render(String.t(), map()) :: map()
  def render("group.json", %{group: %Actor{} = group}) do
    res = %{
      "@context" => "http://schema.org",
      "@type" => "Organization",
      "url" => group.url,
      "name" => group.name || group.preferred_username,
      "address" => render_address(group)
    }

    res =
      if group.banner do
        Map.put(res, "image", group.banner.url)
      else
        res
      end

    if group.physical_address do
      Map.put(
        res,
        "address",
        render_one(group.physical_address, ObjectView, "address.json", as: :address)
      )
    else
      res
    end
  end

  def render("event.json", %{event: %Event{} = event}) do
    organizer = %{
      "@type" => if(event.organizer_actor.type == :Group, do: "Organization", else: "Person"),
      "name" => Actor.display_name(event.organizer_actor)
    }

    organizer =
      if event.organizer_actor.avatar do
        Map.put(organizer, "image", event.organizer_actor.avatar.url)
      else
        organizer
      end

    json_ld = %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.title,
      "description" => process_description(event.description, "en", nil),
      # We assume for now performer == organizer
      "performer" => organizer,
      "organizer" => organizer,
      "location" => render_all_locations(event),
      "eventAttendanceMode" => event |> attendance_mode() |> event_attendance_mode(),
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
      "headline" => post.title,
      "author" => %{
        "@type" => "Organization",
        "name" => Actor.display_name(post.attributed_to),
        "url" =>
          Endpoint
          |> Routes.page_url(
            :actor,
            Actor.preferred_username_and_domain(post.attributed_to)
          )
          |> URI.decode()
      },
      "datePublished" => post.publish_at,
      "dateModified" => post.updated_at,
      "image" =>
        if(post.picture,
          do: [
            post.picture.file.url
          ],
          else: ["#{Endpoint.url()}/img/mobilizon_default_card.png"]
        )
    }
  end

  def render("participation.json", %{
        participant: %Participant{} = participant
      }) do
    res = %{
      "@context" => "http://schema.org",
      "@type" => "EventReservation",
      "underName" => %{
        "@type" => "Person",
        "name" => participant.actor.name || participant.actor.preferred_username
      },
      "reservationFor" => render("event.json", %{event: participant.event}),
      "reservationStatus" => reservation_status(participant.role),
      "modifiedTime" => participant.updated_at,
      "modifyReservationUrl" => Routes.page_url(Endpoint, :event, participant.event.uuid)
    }

    if participant.code do
      Map.put(res, "reservationNumber", participant.code)
    else
      res
    end
  end

  @spec reservation_status(ParticipantRole.t()) :: String.t()
  defp reservation_status(:rejected), do: "https://schema.org/ReservationCancelled"
  defp reservation_status(:not_confirmed), do: "https://schema.org/ReservationPending"
  defp reservation_status(:not_approved), do: "https://schema.org/ReservationHold"
  defp reservation_status(_), do: "https://schema.org/ReservationConfirmed"

  defp render_all_locations(%Event{} = event) do
    []
    |> render_location(event)
    |> render_virtual_location(event)
  end

  @spec render_location(list(), map()) :: list()
  defp render_location(locations, %{physical_address: %Address{} = address}),
    do: locations ++ [render_one(address, ObjectView, "place.json", as: :address)]

  defp render_location(locations, _), do: locations

  # For now the Virtual Location of an event is it's own URL,
  # but in the future it will be a special field
  defp render_virtual_location(locations, %Event{
         url: event_url,
         metadata: metadata,
         options: %EventOptions{is_online: is_online}
       }) do
    links = virtual_location_links(metadata)
    fallback_links = if is_online, do: [event_url], else: []
    links = if length(links) > 0, do: Enum.map(links, & &1.value), else: fallback_links

    locations ++
      Enum.map(
        links,
        &%{
          "@type" => "VirtualLocation",
          "url" => &1
        }
      )
  end

  defp render_virtual_location(locations, _), do: locations

  defp render_address(%{physical_address: %Address{} = address}),
    do: render_one(address, ObjectView, "address.json", as: :address)

  defp render_address(_), do: nil

  defp event_attendance_mode(:online), do: "https://schema.org/OnlineEventAttendanceMode"
  defp event_attendance_mode(:offline), do: "https://schema.org/OfflineEventAttendanceMode"
  defp event_attendance_mode(:mixed), do: "https://schema.org/MixedEventAttendanceMode"

  defp attendance_mode(%Event{options: %EventOptions{is_online: true}}),
    do: :online

  defp attendance_mode(%Event{physical_address: %Address{}, metadata: metadata}) do
    if metadata |> virtual_location_links() |> length() > 0 do
      :mixed
    else
      :offline
    end
  end

  defp attendance_mode(%Event{}),
    do: :offline

  @livestream_keys ["mz:live", "mz:visio"]
  @spec virtual_location_links(list()) :: list()
  defp virtual_location_links(metadata),
    do: Enum.filter(metadata, &String.contains?(&1.key, @livestream_keys))
end
