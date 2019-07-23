defmodule Mobilizon.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Mobilizon.Repo
  alias Mobilizon.Actors.Actor
  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint
  alias MobilizonWeb.Upload

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
      avatar: build(:file, name: "Avatar"),
      banner: build(:file, name: "Banner"),
      url: Actor.build_url(preferred_username, :page),
      followers_url: Actor.build_url(preferred_username, :followers),
      following_url: Actor.build_url(preferred_username, :following),
      outbox_url: Actor.build_url(preferred_username, :outbox),
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
      geom: %Geo.Point{coordinates: {45.75, 4.85}, srid: 4326},
      floor: "Myfloor",
      country: "My Country",
      locality: "My Locality",
      region: "My Region",
      postal_code: "My Postal Code",
      street: "My Street Address"
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
      url: Routes.page_url(Endpoint, :comment, uuid)
    }
  end

  def event_factory do
    actor = build(:actor)
    start = Timex.shift(DateTime.utc_now(), hours: 2)
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
      tags: build_list(3, :tag),
      url: Routes.page_url(Endpoint, :event, uuid),
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

  def feed_token_factory do
    user = build(:user)

    %Mobilizon.Events.FeedToken{
      user: user,
      actor: build(:actor, user: user),
      token: Ecto.UUID.generate()
    }
  end

  def file_factory do
    File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

    file = %Plug.Upload{
      content_type: "image/jpg",
      path: Path.absname("test/fixtures/image_tmp.jpg"),
      filename: "image.jpg"
    }

    {:ok, data} = Upload.store(file)

    %{
      "url" => [%{"href" => url, "mediaType" => "image/jpeg"}],
      "size" => 13_227,
      "type" => "Image"
    } = data

    %Mobilizon.Media.File{
      name: "My Picture",
      url: url,
      content_type: "image/png",
      size: 13_120
    }
  end

  def picture_factory do
    %Mobilizon.Media.Picture{
      file: build(:file),
      actor: build(:actor)
    }
  end

  def report_factory do
    %Mobilizon.Reports.Report{
      content: "This is problematic",
      status: :open,
      uri: "http://mobilizon.test/report/deae1020-54b8-47df-9eea-d8c0e943e57f/activity",
      reported: build(:actor),
      reporter: build(:actor),
      event: build(:event),
      comments: build_list(1, :comment)
    }
  end

  def report_note_factory do
    %Mobilizon.Reports.Note{
      content: "My opinion",
      moderator: build(:actor),
      report: build(:report)
    }
  end
end
