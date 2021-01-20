defmodule Mobilizon.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina.
  """

  use ExMachina.Ecto, repo: Mobilizon.Storage.Repo

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Crypto

  alias Mobilizon.Web.{Endpoint, Upload}
  alias Mobilizon.Web.Router.Helpers, as: Routes

  def user_factory do
    %Mobilizon.Users.User{
      password_hash: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: :user,
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      confirmation_sent_at: nil,
      confirmation_token: nil,
      provider: nil
    }
  end

  def settings_factory do
    %Mobilizon.Users.Setting{
      timezone: nil,
      notification_on_day: false,
      notification_each_week: false,
      notification_before_event: false,
      notification_pending_participation: :one_day,
      notification_pending_membership: :one_day,
      user_id: nil
    }
  end

  def actor_factory do
    preferred_username = sequence("thomas")

    %Mobilizon.Actors.Actor{
      preferred_username: preferred_username,
      domain: nil,
      followers: [],
      followings: [],
      keys: Crypto.generate_rsa_2048_private_key(),
      type: :Person,
      avatar: build(:file, name: "Avatar"),
      banner: build(:file, name: "Banner"),
      url: Actor.build_url(preferred_username, :page),
      followers_url: Actor.build_url(preferred_username, :followers),
      following_url: Actor.build_url(preferred_username, :following),
      inbox_url: Actor.build_url(preferred_username, :inbox),
      outbox_url: Actor.build_url(preferred_username, :outbox),
      shared_inbox_url: "#{Endpoint.url()}/inbox",
      last_refreshed_at: DateTime.utc_now(),
      user: build(:user),
      visibility: :public,
      manually_approves_followers: false
    }
  end

  def group_factory do
    preferred_username = sequence("myGroup")

    struct!(
      actor_factory(),
      %{
        preferred_username: preferred_username,
        type: :Group,
        url: Actor.build_url(preferred_username, :page),
        followers_url: Actor.build_url(preferred_username, :followers),
        following_url: Actor.build_url(preferred_username, :following),
        members_url: Actor.build_url(preferred_username, :members),
        resources_url: Actor.build_url(preferred_username, :resources),
        inbox_url: Actor.build_url(preferred_username, :inbox),
        outbox_url: Actor.build_url(preferred_username, :outbox),
        user: nil
      }
    )
  end

  def instance_actor_factory do
    preferred_username = "relay"
    domain = "#{sequence("mydomain")}.com"

    struct!(
      actor_factory(),
      %{
        preferred_username: preferred_username,
        type: :Application,
        url: "http://#{domain}/#{preferred_username}",
        followers_url: Actor.build_url(preferred_username, :followers),
        following_url: Actor.build_url(preferred_username, :following),
        members_url: Actor.build_url(preferred_username, :members),
        resources_url: Actor.build_url(preferred_username, :resources),
        inbox_url: Actor.build_url(preferred_username, :inbox),
        outbox_url: Actor.build_url(preferred_username, :outbox),
        user: nil,
        domain: domain
      }
    )
  end

  def follower_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Actors.Follower{
      target_actor: build(:actor),
      actor: build(:actor),
      id: uuid,
      url: "#{Endpoint.url()}/follows/#{uuid}",
      approved: false
    }
  end

  def tag_factory do
    %Mobilizon.Events.Tag{
      title: sequence("MyTag"),
      slug: sequence("my-tag")
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
      url: "http://mobilizon.test/address/#{Ecto.UUID.generate()}",
      country: "My Country",
      locality: "My Locality",
      region: "My Region",
      postal_code: "My Postal Code",
      street: "My Street Address"
    }
  end

  def comment_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Discussions.Comment{
      text: "My Comment",
      actor: build(:actor),
      event: build(:event),
      uuid: uuid,
      mentions: [],
      media: [],
      attributed_to: nil,
      local: true,
      deleted_at: nil,
      tags: build_list(3, :tag),
      in_reply_to_comment: nil,
      published_at: DateTime.utc_now(),
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
      attributed_to: nil,
      category: sequence("something"),
      physical_address: build(:address),
      visibility: :public,
      tags: build_list(3, :tag),
      mentions: [],
      local: true,
      publish_at: DateTime.utc_now(),
      url: Routes.page_url(Endpoint, :event, uuid),
      picture: insert(:media),
      uuid: uuid,
      join_options: :free,
      options: %{},
      participant_stats: %{},
      status: :confirmed,
      contacts: [],
      media: []
    }
  end

  def participant_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Events.Participant{
      event: build(:event),
      actor: build(:actor),
      role: :creator,
      url: "#{Endpoint.url()}/join/event/#{uuid}",
      id: uuid,
      metadata: %{
        email: nil,
        confirmation_token: nil
      }
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
    uuid = Ecto.UUID.generate()

    %Mobilizon.Actors.Member{
      parent: build(:actor),
      actor: build(:actor),
      role: :not_approved,
      id: uuid,
      url: "#{Endpoint.url()}/member/#{uuid}"
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
      content_type: "image/jpeg",
      name: "image.jpg",
      url: url,
      size: 13_227
    } = data

    %Mobilizon.Medias.File{
      name: "My Media",
      url: url,
      content_type: "image/png",
      size: 13_120
    }
  end

  def media_factory do
    %Mobilizon.Medias.Media{
      file: build(:file),
      actor: build(:actor)
    }
  end

  def report_factory do
    %Mobilizon.Reports.Report{
      content: "This is problematic",
      status: :open,
      url: "http://mobilizon.test/report/deae1020-54b8-47df-9eea-d8c0e943e57f/activity",
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

  def todo_list_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Todos.TodoList{
      title: sequence("todo list"),
      actor: build(:group),
      id: uuid,
      url: Routes.page_url(Endpoint, :todo_list, uuid),
      published_at: DateTime.utc_now()
    }
  end

  def todo_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Todos.Todo{
      id: uuid,
      title: sequence("my todo"),
      todo_list: build(:todo_list),
      status: false,
      due_date: Timex.shift(DateTime.utc_now(), hours: 2),
      assigned_to: build(:actor),
      url: Routes.page_url(Endpoint, :todo, uuid),
      creator: build(:actor),
      published_at: DateTime.utc_now()
    }
  end

  def resource_factory do
    uuid = Ecto.UUID.generate()
    title = sequence("my resource")

    %Mobilizon.Resources.Resource{
      id: uuid,
      title: title,
      type: :link,
      resource_url: "https://somewebsite.com/path",
      actor: build(:group),
      creator: build(:actor),
      parent: nil,
      url: Routes.page_url(Endpoint, :resource, uuid),
      published_at: DateTime.utc_now(),
      path: "/#{title}"
    }
  end

  def admin_setting_factory do
    %Mobilizon.Admin.Setting{
      group: sequence("group"),
      name: sequence("name"),
      value: sequence("value")
    }
  end

  def post_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Posts.Post{
      body: "The <b>HTML</b>body for my Article",
      title: "My Awesome article",
      slug: "my-awesome-article-#{ShortUUID.encode!(uuid)}",
      author: build(:actor),
      attributed_to: build(:group),
      id: uuid,
      draft: false,
      tags: build_list(3, :tag),
      visibility: :public,
      publish_at: DateTime.utc_now(),
      picture: insert(:media),
      media: [],
      url: Routes.page_url(Endpoint, :post, uuid)
    }
  end

  def tombstone_factory do
    uuid = Ecto.UUID.generate()

    %Mobilizon.Tombstone{
      uri: "https://mobilizon.test/comments/#{uuid}",
      actor: build(:actor)
    }
  end

  def discussion_factory do
    uuid = Ecto.UUID.generate()
    actor = build(:actor)
    group = build(:group)
    comment = build(:comment, actor: actor, attributed_to: group)
    slug = "my-awesome-discussion-#{ShortUUID.encode!(uuid)}"

    %Mobilizon.Discussions.Discussion{
      title: "My Awesome discussion",
      slug: slug,
      creator: actor,
      actor: group,
      id: uuid,
      last_comment: comment,
      comments: [comment],
      url: Routes.page_url(Endpoint, :discussion, group.preferred_username, slug)
    }
  end
end
