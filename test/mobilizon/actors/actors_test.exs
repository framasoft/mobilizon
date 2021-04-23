defmodule Mobilizon.ActorsTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory

  alias Mobilizon.{Actors, Config, Discussions, Events, Tombstone, Users}
  alias Mobilizon.Actors.{Actor, Bot, Follower, Member}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Medias.File, as: FileModel
  alias Mobilizon.Service.Workers
  alias Mobilizon.Storage.Page

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor

  alias Mobilizon.Web.Upload.Uploader

  describe "actors" do
    @valid_attrs %{
      summary: "some description",
      name: "Bobby Blank",
      domain: "some domain",
      keys: "some keypair",
      suspended: true,
      uri: "some uri",
      url: "some url",
      preferred_username: "some username"
    }
    @update_attrs %{
      summary: "some updated description",
      name: "some updated name",
      domain: "some updated domain",
      keys: "some updated keys",
      suspended: false,
      uri: "some updated uri",
      url: "some updated url",
      preferred_username: "some updated username"
    }
    @invalid_attrs %{
      summary: nil,
      name: nil,
      domain: nil,
      keys: nil,
      suspended: nil,
      uri: nil,
      url: nil,
      preferred_username: "never"
    }

    @remote_account_url "https://social.tcit.fr/users/tcit"

    setup do
      user = insert(:user)
      actor = insert(:actor, user: user, preferred_username: "tcit")

      {:ok, actor: actor}
    end

    test "list_actors/0 returns all actors", %{actor: %Actor{id: actor_id}} do
      assert %Page{total: 1, elements: [%Actor{id: id}]} = Actors.list_actors()
      assert id == actor_id
    end

    test "get_actor!/1 returns the actor with given id", %{actor: %Actor{id: actor_id} = actor} do
      assert actor_id == Actors.get_actor!(actor.id).id
    end

    test "get_actor_for_user/1 returns the actor for an user", %{
      actor: %{user: user, id: actor_id} = _actor
    } do
      assert actor_id == Users.get_actor_for_user(user).id
    end

    test "get_actor_for_user/1 returns the actor for an user with no default actor defined" do
      user = insert(:user)
      actor_id = insert(:actor, user: user).id
      assert actor_id == Users.get_actor_for_user(user).id
    end

    test "get_actor_with_preload/1 returns the actor with its organized events", %{
      actor: actor
    } do
      assert Actors.get_actor_with_preload(actor.id).organized_events == []
      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_actor_with_preload(actor.id).organized_events |> hd |> Map.get(:id)

      assert event_found_id == event.id
    end

    test "get_actor_by_name/1 returns a local actor", %{
      actor: %Actor{id: actor_id, preferred_username: preferred_username}
    } do
      actor_found_id = Actors.get_actor_by_name(preferred_username).id
      assert actor_found_id == actor_id
    end

    test "get_actor_by_name/1 returns a remote actor" do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        {:ok,
         %Actor{
           id: actor_id,
           preferred_username: preferred_username,
           domain: domain,
           avatar: %FileModel{name: picture_name} = _picture
         } = _actor} = ActivityPubActor.get_or_fetch_actor_by_url(@remote_account_url)

        assert picture_name == "a28c50ce5f2b13fd.jpg"

        %Actor{
          id: actor_found_id,
          avatar: %FileModel{name: picture_name} = _picture
        } = Actors.get_actor_by_name("#{preferred_username}@#{domain}")

        assert actor_found_id == actor_id
        assert picture_name == "a28c50ce5f2b13fd.jpg"
      end
    end

    test "get_local_actor_by_name_with_preload!/1 returns the local actor with its organized events",
         %{
           actor: actor
         } do
      assert Actors.get_local_actor_by_name_with_preload(actor.preferred_username).organized_events ==
               []

      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_local_actor_by_name_with_preload(actor.preferred_username).organized_events
        |> hd
        |> Map.get(:id)

      assert event_found_id == event.id
    end

    test "get_actor_by_name_with_preload!/1 returns the local actor with its organized events",
         %{
           actor: actor
         } do
      assert Actors.get_actor_by_name_with_preload(actor.preferred_username).organized_events ==
               []

      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_actor_by_name_with_preload(actor.preferred_username).organized_events
        |> hd
        |> Map.get(:id)

      assert event_found_id == event.id
    end

    test "get_actor_by_name_with_preload!/1 returns the remote actor with its organized events" do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        with {:ok, %Actor{} = actor} <-
               ActivityPubActor.get_or_fetch_actor_by_url(@remote_account_url) do
          assert Actors.get_actor_by_name_with_preload(
                   "#{actor.preferred_username}@#{actor.domain}"
                 ).organized_events == []

          event = insert(:event, organizer_actor: actor)

          event_found_id =
            Actors.get_actor_by_name_with_preload("#{actor.preferred_username}@#{actor.domain}").organized_events
            |> hd
            |> Map.get(:id)

          assert event_found_id == event.id
        end
      end
    end

    test "test list_local_actor_by_username/1 returns local actors with similar usernames", %{
      actor: actor
    } do
      actor2 = insert(:actor, preferred_username: "tcit")
      [%Actor{id: actor_found_id} | tail] = Actors.list_local_actor_by_username("tcit")
      %Actor{id: actor2_found_id} = hd(tail)
      assert MapSet.new([actor_found_id, actor2_found_id]) == MapSet.new([actor.id, actor2.id])
    end

    test "test build_actors_by_username_or_name_page/4 returns actors with similar usernames",
         %{actor: %Actor{id: actor_id}} do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        with {:ok, %Actor{id: actor2_id}} <-
               ActivityPubActor.get_or_fetch_actor_by_url(@remote_account_url) do
          %Page{total: 2, elements: actors} =
            Actors.build_actors_by_username_or_name_page("tcit",
              actor_type: [:Person],
              minimum_visibility: :private
            )

          actors_ids = actors |> Enum.map(& &1.id)

          assert MapSet.new(actors_ids) == MapSet.new([actor2_id, actor_id])
        end
      end
    end

    test "test build_actors_by_username_or_name_page/4 returns actors with similar names" do
      %{total: 0, elements: actors} =
        Actors.build_actors_by_username_or_name_page("ohno", actor_type: [:Person])

      assert actors == []
    end

    test "create_actor/1 with valid data creates a actor" do
      assert {:ok, %Actor{} = actor} = Actors.create_actor(@valid_attrs)
      assert actor.summary == "some description"
      assert actor.name == "Bobby Blank"
      assert actor.domain == "some domain"
      assert actor.keys == "some keypair"
      assert actor.suspended
      assert actor.preferred_username == "some username"
    end

    test "create_actor/1 with empty data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actors.create_actor()
    end

    test "create_actor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actors.create_actor(@invalid_attrs)
    end

    test "update_actor/2 with valid data updates the actor", %{
      actor: %Actor{} = actor
    } do
      assert {:ok, actor} =
               Actors.update_actor(
                 actor,
                 @update_attrs
               )

      assert %Actor{} = actor
      assert actor.summary == "some updated description"
      assert actor.name == "some updated name"
      assert actor.keys == "some updated keys"
      refute actor.suspended
    end

    test "update_actor/2 with valid data updates the actor and its media files", %{
      actor: %Actor{avatar: %{url: avatar_url}, banner: %{url: banner_url}} = actor
    } do
      %URI{path: "/media/" <> avatar_path} = URI.parse(avatar_url)
      %URI{path: "/media/" <> banner_path} = URI.parse(banner_url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image.jpg"),
        filename: "image.jpg"
      }

      {:ok, data} = Mobilizon.Web.Upload.store(file)

      assert {:ok, actor} =
               Actors.update_actor(
                 actor,
                 Map.put(@update_attrs, :avatar, %{name: file.filename, url: data.url})
               )

      assert %Actor{} = actor
      assert actor.summary == "some updated description"
      assert actor.name == "some updated name"
      assert actor.keys == "some updated keys"
      refute actor.suspended

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )
    end

    test "update_actor/2 with invalid data returns error changeset", %{actor: actor} do
      assert {:error, %Ecto.Changeset{}} = Actors.update_actor(actor, @invalid_attrs)
      actor_fetched = Actors.get_actor!(actor.id)
      assert actor = actor_fetched
    end

    test "perform delete the actor actually deletes the actor", %{
      actor: %Actor{avatar: %{url: avatar_url}, banner: %{url: banner_url}, id: actor_id} = actor
    } do
      %Event{url: event1_url} = event1 = insert(:event, organizer_actor: actor)
      insert(:event, organizer_actor: actor)

      %Comment{url: comment1_url} = comment1 = insert(:comment, actor: actor)
      insert(:comment, actor: actor)

      %URI{path: "/media/" <> avatar_path} = URI.parse(avatar_url)
      %URI{path: "/media/" <> banner_path} = URI.parse(banner_url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )

      assert {:ok, %Actor{}} = Actors.perform(:delete_actor, actor)

      assert %Actor{
               name: nil,
               summary: nil,
               suspended: true,
               avatar: nil,
               banner: nil,
               user_id: nil
             } = Actors.get_actor(actor_id)

      assert {:error, :event_not_found} = Events.get_event(event1.id)
      assert %Tombstone{} = Tombstone.find_tombstone(event1_url)
      assert %Comment{deleted_at: deleted_at} = Discussions.get_comment(comment1.id)
      refute is_nil(deleted_at)
      assert %Tombstone{} = Tombstone.find_tombstone(comment1_url)

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )
    end

    test "delete_actor/1 deletes the actor", %{
      actor: %Actor{avatar: %{url: avatar_url}, banner: %{url: banner_url}, id: actor_id} = actor
    } do
      %Event{url: event1_url} = event1 = insert(:event, organizer_actor: actor)
      insert(:event, organizer_actor: actor)

      %Comment{url: comment1_url} = comment1 = insert(:comment, actor: actor)
      insert(:comment, actor: actor)

      %URI{path: "/media/" <> avatar_path} = URI.parse(avatar_url)
      %URI{path: "/media/" <> banner_path} = URI.parse(banner_url)

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      assert File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )

      assert {:ok, %Oban.Job{}} = Actors.delete_actor(actor)

      assert_enqueued(
        worker: Workers.Background,
        args: %{
          "actor_id" => actor.id,
          "op" => "delete_actor",
          "author_id" => nil,
          "suspension" => false,
          "reserve_username" => true
        }
      )

      assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :background)

      assert %Actor{
               name: nil,
               summary: nil,
               suspended: true,
               avatar: nil,
               banner: nil,
               user_id: nil
             } = Actors.get_actor(actor_id)

      assert {:error, :event_not_found} = Events.get_event(event1.id)
      assert %Tombstone{} = Tombstone.find_tombstone(event1_url)
      assert %Comment{deleted_at: deleted_at} = Discussions.get_comment(comment1.id)
      refute is_nil(deleted_at)
      assert %Tombstone{} = Tombstone.find_tombstone(comment1_url)

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> avatar_path
             )

      refute File.exists?(
               Config.get!([Uploader.Local, :uploads]) <>
                 "/" <> banner_path
             )
    end
  end

  describe "groups" do
    @valid_attrs %{
      summary: "some description",
      suspended: true,
      preferred_username: "some-title",
      name: "Some Title"
    }
    @update_attrs %{
      summary: "some updated description",
      suspended: false,
      preferred_username: "some-updated-title",
      name: "Some Updated Title"
    }
    @invalid_attrs %{summary: nil, suspended: nil, preferred_username: nil, name: nil}

    test "create_group/1 with valid data creates a group" do
      %Actor{id: actor_id} = insert(:actor)

      assert {:ok, %Actor{} = group} =
               Actors.create_group(Map.put(@valid_attrs, :creator_actor_id, actor_id))

      assert group.summary == "some description"
      refute group.suspended
      assert group.preferred_username == "some-title"
    end

    test "create_group/1 with an existing profile username fails" do
      _actor = insert(:actor, preferred_username: @valid_attrs.preferred_username)

      assert {:error, :insert_group,
              %Ecto.Changeset{
                errors: [preferred_username: {"This username is already taken.", []}]
              }, %{}} = Actors.create_group(@valid_attrs)
    end

    test "create_group/1 with an existing group username fails" do
      %Actor{id: actor_id} = insert(:actor)
      attrs = Map.put(@valid_attrs, :creator_actor_id, actor_id)
      assert {:ok, %Actor{} = group} = Actors.create_group(attrs)

      assert {:error, :insert_group,
              %Ecto.Changeset{
                errors: [preferred_username: {"This username is already taken.", []}]
              }, %{}} = Actors.create_group(attrs)
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, :insert_group, %Ecto.Changeset{}, %{}} = Actors.create_group(@invalid_attrs)
    end
  end

  describe "bots" do
    @valid_attrs %{source: "some source", type: "some type"}
    @update_attrs %{source: "some updated source", type: "some updated type"}
    @invalid_attrs %{source: nil, type: nil}

    test "list_bots/0 returns all bots" do
      bot = insert(:bot)
      bot_found_id = Actors.list_bots() |> hd |> Map.get(:id)
      assert bot_found_id == bot.id
    end

    test "get_bot!/1 returns the bot with given id" do
      %Bot{id: bot_id} = bot = insert(:bot)
      assert bot_id == Actors.get_bot!(bot.id).id
    end

    test "create_bot/1 with valid data creates a bot" do
      attrs =
        @valid_attrs
        |> Map.merge(%{actor_id: insert(:actor).id})
        |> Map.merge(%{user_id: insert(:user).id})

      assert {:ok, %Bot{} = bot} = Actors.create_bot(attrs)
      assert bot.source == "some source"
      assert bot.type == "some type"
    end

    test "create_bot/1 with invalid data returns error changeset" do
      case Actors.create_bot(@invalid_attrs) do
        {:error, %Ecto.Changeset{}} ->
          assert true

        _ ->
          assert false
      end
    end

    test "update_bot/2 with valid data updates the bot" do
      with bot <- insert(:bot),
           {:ok, %Bot{source: source, type: type}} <- Actors.update_bot(bot, @update_attrs) do
        assert source == "some updated source"
        assert type == "some updated type"
      end
    end

    test "update_bot/2 with invalid data returns error changeset" do
      bot = insert(:bot)
      assert {:error, %Ecto.Changeset{}} = Actors.update_bot(bot, @invalid_attrs)
      assert bot = Actors.get_bot!(bot.id)
    end

    test "delete_bot/1 deletes the bot" do
      bot = insert(:bot)
      assert {:ok, %Bot{}} = Actors.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_bot!(bot.id) end
    end
  end

  describe "followers" do
    @valid_attrs %{approved: true}
    @update_attrs %{approved: false}
    @invalid_attrs %{approved: nil}

    setup do
      actor = insert(:actor)
      target_actor = insert(:actor)
      {:ok, actor: actor, target_actor: target_actor}
    end

    defp create_test_follower(%{actor: actor, target_actor: target_actor}) do
      insert(:follower, actor: actor, target_actor: target_actor)
    end

    test "get_follower!/1 returns the follower with given id", context do
      follower = create_test_follower(context)
      assert follower = Actors.get_follower!(follower.id)
    end

    test "create_follower/1 with valid data creates a follower", %{
      actor: actor,
      target_actor: target_actor
    } do
      valid_attrs =
        @valid_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:target_actor_id, target_actor.id)

      assert {:ok, %Follower{} = follower} = Actors.create_follower(valid_attrs)
      assert follower.approved == true

      assert %{total: 1, elements: [target_actor]} = Actors.build_followings_for_actor(actor)
      assert %{total: 1, elements: [actor]} = Actors.build_followers_for_actor(target_actor)
    end

    test "create_follower/1 with valid data but same actors fails to create a follower", %{
      actor: actor,
      target_actor: target_actor
    } do
      create_test_follower(%{actor: actor, target_actor: target_actor})

      valid_attrs =
        @valid_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:target_actor_id, target_actor.id)

      assert {:error, _follower} = Actors.create_follower(valid_attrs)
    end

    test "create_follower/1 with invalid data returns error changeset", %{
      actor: actor,
      target_actor: target_actor
    } do
      invalid_attrs =
        @invalid_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:target_actor_id, target_actor.id)

      assert {:error, %Ecto.Changeset{}} = Actors.create_follower(invalid_attrs)
    end

    test "update_follower/2 with valid data updates the follower", context do
      follower = create_test_follower(context)
      assert {:ok, follower} = Actors.update_follower(follower, @update_attrs)
      assert %Follower{} = follower
      assert follower.approved == false
    end

    test "update_follower/2 with invalid data returns error changeset", context do
      follower = create_test_follower(context)
      assert {:error, %Ecto.Changeset{}} = Actors.update_follower(follower, @invalid_attrs)
      assert follower = Actors.get_follower!(follower.id)
    end

    test "delete_follower/1 deletes the follower", context do
      follower = create_test_follower(context)
      assert {:ok, %Follower{}} = Actors.delete_follower(follower)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_follower!(follower.id) end
    end

    test "follow/3 makes an actor follow another", %{actor: actor, target_actor: target_actor} do
      # Preloading followers/followings
      actor = Actors.get_actor_with_preload(actor.id)
      target_actor = Actors.get_actor_with_preload(target_actor.id)

      {:ok, follower} = Actors.follow(target_actor, actor)
      assert follower.actor.id == actor.id

      # Referesh followers/followings
      actor = Actors.get_actor_with_preload(actor.id)
      target_actor = Actors.get_actor_with_preload(target_actor.id)

      assert target_actor.followers |> Enum.map(& &1.actor_id) == [actor.id]
      assert actor.followings |> Enum.map(& &1.target_actor_id) == [target_actor.id]

      # Test if actor is already following target actor
      assert {:error, :already_following, msg} = Actors.follow(target_actor, actor)
      assert msg =~ "already following"

      # Test if target actor is suspended
      target_actor = %{target_actor | suspended: true}
      assert {:error, :suspended, msg} = Actors.follow(target_actor, actor)
      assert msg =~ "suspended"
    end
  end

  describe "members" do
    @valid_attrs %{role: :member}
    @update_attrs %{role: :not_approved}
    @invalid_attrs %{role: nil}

    setup do
      actor = insert(:actor)
      group = insert(:group)
      {:ok, actor: actor, group: group}
    end

    defp create_test_member(%{actor: actor, group: group}) do
      insert(:member, actor: actor, parent: group)
    end

    test "get_member!/1 returns the member with given id", context do
      member = create_test_member(context)
      assert member = Actors.get_member!(member.id)
    end

    test "create_member/1 with valid data creates a member", %{
      actor: actor,
      group: group
    } do
      valid_attrs =
        @valid_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:parent_id, group.id)

      assert {:ok, %Member{} = member} = Actors.create_member(valid_attrs)
      assert member.role == :member

      assert [group] = Actors.list_groups_member_of(actor)
      assert %Page{elements: [actor], total: 1} = Actors.list_members_for_group(group)
    end

    test "create_member/1 with valid data but same actors just updates the member", %{
      actor: actor,
      group: group
    } do
      %Member{id: member_id, url: member_url} = create_test_member(%{actor: actor, group: group})

      attrs =
        %{}
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:parent_id, group.id)
        |> Map.put(:role, :member)

      assert {:ok,
              %Member{
                id: updated_member_id,
                role: updated_member_role,
                actor_id: actor_id,
                parent_id: parent_id,
                url: url
              }} = Actors.create_member(attrs)

      assert updated_member_role == :member
      assert actor_id == actor.id
      assert parent_id == group.id

      assert url == member_url
      assert updated_member_id == member_id
    end

    test "create_member/1 with invalid data returns error changeset" do
      invalid_attrs =
        @invalid_attrs
        |> Map.put(:actor_id, nil)
        |> Map.put(:parent_id, nil)

      assert {:error, %Ecto.Changeset{}} = Actors.create_member(invalid_attrs)
    end

    test "update_member/2 with valid data updates the member", context do
      member = create_test_member(context)
      assert {:ok, member} = Actors.update_member(member, @update_attrs)
      assert %Member{} = member
      assert member.role == :not_approved
    end

    # This can't happen, since attrs are optional
    # test "update_member/2 with invalid data returns error changeset", context do
    #   member = create_member(context)
    #   assert {:error, %Ecto.Changeset{}} = Actors.update_member(member, @invalid_attrs)
    #   assert member = Actors.get_member!(member.id)
    # end

    test "delete_member/1 deletes the member", context do
      member = create_test_member(context)
      assert {:ok, %Member{}} = Actors.delete_member(member)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_member!(member.id) end
    end
  end
end
