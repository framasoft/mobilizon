defmodule Mobilizon.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Mobilizon.Repo

  def user_factory do
    %Mobilizon.Users.User{
      password_hash: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: :user,
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      confirmation_sent_at: nil,
      confirmation_token: nil
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
      followers: [],
      followings: [],
      keys: pem,
      type: :Person,
      url: MobilizonWeb.Endpoint.url() <> "/@#{preferred_username}",
      followers_url: MobilizonWeb.Endpoint.url() <> "/@#{preferred_username}/followers",
      following_url: MobilizonWeb.Endpoint.url() <> "/@#{preferred_username}/following",
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

  def tag_factory do
    %Mobilizon.Events.Tag{
      title: "MyTag",
      slug: sequence("MyTag")
    }
  end

  def tag_relation_factory do
    %Mobilizon.Events.TagRelation{
      tag: build(:tag),
      link: build(:tag)
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
      in_reply_to_comment: nil,
      url: "#{MobilizonWeb.Endpoint.url()}/comments/#{uuid}"
    }
  end

  def event_factory do
    actor = build(:actor)
    start = Timex.now()
    uuid = Ecto.UUID.generate()

    %Mobilizon.Events.Event{
      title: sequence("Ceci est un événement"),
      description: "Ceci est une description avec une première phrase assez longue,
      puis sur une seconde ligne",
      begins_on: start,
      ends_on: Timex.shift(start, hours: 2),
      organizer_actor: actor,
      category: sequence("something"),
      physical_address: build(:address),
      visibility: :public,
      url: "#{actor.url}/#{uuid}",
      uuid: uuid
    }
  end

  def participant_factory do
    %Mobilizon.Events.Participant{
      event: build(:event),
      actor: build(:actor),
      role: :creator
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
      actor: build(:actor),
      role: :not_approved
    }
  end
end
