defmodule Eventos.Factory do
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
    {:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")
    %Eventos.Accounts.Account{
      username: sequence("Thomas"),
      domain: nil,
      public_key: pubkey,
      uri: "https://",
      url: "https://"
    }
  end

  def event_factory do
    %Eventos.Events.Event{
      title: sequence("MyEvent"),
      slug: sequence("my-event"),
      description: "My desc",
      begins_on: nil,
      ends_on: nil,
      organizer: build(:account)
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
end