defmodule Eventos.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Eventos.Repo

  def user_factory do
    %Eventos.Accounts.User{
      password_hash: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: 0,
      account: build(:account)
    }
  end

  def account_factory do
    {:ok, {_, pubkey}} = RsaEx.generate_keypair("4096")
    %Eventos.Accounts.Account{
      username: sequence("Thomas"),
      domain: nil,
      public_key: pubkey,
      uri: "https://",
      url: "https://"
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

  def event_factory do
    %Eventos.Events.Event{
      title: sequence("MyEvent"),
      slug: sequence("my-event"),
      description: "My desc",
      begins_on: nil,
      ends_on: nil,
      organizer_account: build(:account),
      category: build(:category),
      address: build(:address)
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

  def group_factory do
    %Eventos.Groups.Group{
      title: sequence("My Group"),
      description: "My group",
      suspended: false,
      url: "https://",
      uri: "https://",
      address: build(:address)
    }
  end
end
