defmodule Mobilizon.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Mobilizon.Repo

  def user_factory do
    %Mobilizon.Actors.User{
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

    %Mobilizon.Actors.Actor{
      preferred_username: preferred_username,
      domain: nil,
      keys: pem,
      type: :Person,
      url: MobilizonWeb.Endpoint.url() <> "/@#{preferred_username}",
      user: nil
    }
  end

  def group_factory do
    struct!(
      actor_factory(),
      %{
        type: :Group
      }
    )
  end

  def follower_factory do
    %Mobilizon.Actors.Follower{
      target_actor: build(:actor),
      actor: build(:actor)
    }
  end

  def category_factory do
    %Mobilizon.Events.Category{
      title: sequence("MyCategory"),
      description: "My category desc"
    }
  end

  def tag_factory do
    %Mobilizon.Events.Tag{
      title: "MyTag",
      slug: sequence("MyTag")
    }
  end

  def address_factory do
    %Mobilizon.Addresses.Address{
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
    uuid = Ecto.UUID.generate()

    %Mobilizon.Events.Comment{
      text: "My Comment",
      actor: build(:actor),
      event: build(:event),
      uuid: uuid,
      url: "#{MobilizonWeb.Endpoint.url()}/comments/#{uuid}"
    }
  end

  def event_factory do
    actor = build(:actor)

    %Mobilizon.Events.Event{
      title: sequence("Ceci est un événement"),
      description: "Ceci est une description avec une première phrase assez longue,
      puis sur une seconde ligne",
      begins_on: nil,
      ends_on: nil,
      organizer_actor: actor,
      category: build(:category),
      physical_address: build(:address),
      public: true,
      url: "@#{actor.url}/#{Ecto.UUID.generate()}"
    }
  end

  def participant_factory do
    %Mobilizon.Events.Participant{
      event: build(:event),
      actor: build(:actor)
    }
  end

  def session_factory do
    %Mobilizon.Events.Session{
      title: sequence("MySession"),
      event: build(:event),
      track: build(:track)
    }
  end

  def track_factory do
    %Mobilizon.Events.Track{
      name: sequence("MyTrack"),
      event: build(:event)
    }
  end

  def bot_factory do
    %Mobilizon.Actors.Bot{
      source: "https://mysource.tld/feed.ics",
      type: "ics",
      user: build(:user),
      actor: build(:actor)
    }
  end

  def member_factory do
    %Mobilizon.Actors.Member{
      parent: build(:actor),
      actor: build(:actor)
    }
  end
end
