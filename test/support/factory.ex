defmodule Eventos.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Eventos.Repo

  def user_factory do
    %Eventos.Actors.User{
      password_hash: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: 0
    }
  end

  def actor_factory do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()

    preferred_username = sequence("thomas")

    %Eventos.Actors.Actor{
      preferred_username: preferred_username,
      domain: nil,
      keys: pem,
      url: EventosWeb.Endpoint.url() <> "/@#{preferred_username}",
      user: nil
    }
  end

  def category_factory do
    %Eventos.Events.Category{
      title: sequence("MyCategory"),
      description: "My category desc"
    }
  end

  def address_factory do
    %Eventos.Addresses.Address{
      description: sequence("MyAddress"),
      geom: %Geo.Point{coordinates: {30, -90}, srid: 4326},
      floor: "Myfloor",
      addressCountry: "My Country",
      addressLocality: "My Locality",
      addressRegion: "My Region",
      postalCode: "My Postal Code",
      streetAddress: "My Street Address"
    }
  end

  def comment_factory do
    %Eventos.Events.Comment{
      text: "My Comment",
      actor: build(:actor),
      event: build(:event),
      uuid: Ecto.UUID.generate()
    }
  end

  def event_factory do
    actor = build(:actor)

    %Eventos.Events.Event{
      title: sequence("MyEvent"),
      description: "My desc",
      begins_on: nil,
      ends_on: nil,
      organizer_actor: actor,
      category: build(:category),
      physical_address: build(:address),
      url: "#{EventosWeb.Endpoint.url()}/@#{actor.url}/#{Ecto.UUID.generate()}"
    }
  end

  def session_factory do
    %Eventos.Events.Session{
      title: sequence("MySession"),
      event: build(:event),
      track: build(:track)
    }
  end

  def track_factory do
    %Eventos.Events.Track{
      name: sequence("MyTrack"),
      event: build(:event)
    }
  end

  def bot_factory do
    %Eventos.Actors.Bot{
      source: "https://mysource.tld/feed.ics",
      type: "ics",
      user: build(:user),
      actor: build(:actor)
    }
  end

  def member_factory do
    %Eventos.Actors.Member{
      parent: build(:actor),
      actor: build(:actor)
    }
  end
end
