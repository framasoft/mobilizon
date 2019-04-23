defmodule Mobilizon.ActorsTest do
  use Mobilizon.DataCase

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member, Follower, Bot}
  alias Mobilizon.Users
  import Mobilizon.Factory
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

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
    @remote_account_username "tcit"
    @remote_account_domain "social.tcit.fr"

    setup do
      user = insert(:user)
      actor = insert(:actor, user: user, preferred_username: "tcit")

      {:ok, actor: actor}
    end

    test "list_actors/0 returns all actors", %{actor: %Actor{id: actor_id}} do
      assert actor_id == hd(Actors.list_actors()).id
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

    test "get_actor_with_everything/1 returns the actor with it's organized events", %{
      actor: actor
    } do
      assert Actors.get_actor_with_everything(actor.id).organized_events == []
      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_actor_with_everything(actor.id).organized_events |> hd |> Map.get(:id)

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
        with {:ok,
              %Actor{id: actor_id, preferred_username: preferred_username, domain: domain} =
                _actor} <- Actors.get_or_fetch_by_url(@remote_account_url),
             %Actor{id: actor_found_id} <-
               Actors.get_actor_by_name("#{preferred_username}@#{domain}").id do
          assert actor_found_id == actor_id
        end
      end
    end

    test "get_local_actor_by_name_with_everything!/1 returns the local actor with it's organized events",
         %{
           actor: actor
         } do
      assert Actors.get_local_actor_by_name_with_everything(actor.preferred_username).organized_events ==
               []

      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_local_actor_by_name_with_everything(actor.preferred_username).organized_events
        |> hd
        |> Map.get(:id)

      assert event_found_id == event.id
    end

    test "get_actor_by_name_with_everything!/1 returns the local actor with it's organized events",
         %{
           actor: actor
         } do
      assert Actors.get_actor_by_name_with_everything(actor.preferred_username).organized_events ==
               []

      event = insert(:event, organizer_actor: actor)

      event_found_id =
        Actors.get_actor_by_name_with_everything(actor.preferred_username).organized_events
        |> hd
        |> Map.get(:id)

      assert event_found_id == event.id
    end

    test "get_actor_by_name_with_everything!/1 returns the remote actor with it's organized events" do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        with {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(@remote_account_url) do
          assert Actors.get_actor_by_name_with_everything(
                   "#{actor.preferred_username}@#{actor.domain}"
                 ).organized_events == []

          event = insert(:event, organizer_actor: actor)

          event_found_id =
            Actors.get_actor_by_name_with_everything(
              "#{actor.preferred_username}@#{actor.domain}"
            ).organized_events
            |> hd
            |> Map.get(:id)

          assert event_found_id == event.id
        end
      end
    end

    test "get_or_fetch_by_url/1 returns the local actor for the url", %{
      actor: %Actor{preferred_username: preferred_username} = actor
    } do
      with {:ok, %Actor{domain: domain} = actor} <- Actors.get_or_fetch_by_url(actor.url) do
        assert preferred_username == actor.preferred_username
        assert is_nil(domain)
      end
    end

    test "get_or_fetch_by_url/1 returns the remote actor for the url" do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        with {:ok, %Actor{preferred_username: preferred_username, domain: domain}} <-
               Actors.get_or_fetch_by_url!(@remote_account_url) do
          assert preferred_username == @remote_account_username
          assert domain == @remote_account_domain
        end
      end
    end

    test "test find_local_by_username/1 returns local actors with similar usernames", %{
      actor: actor
    } do
      actor2 = insert(:actor, preferred_username: "tcit")
      [%Actor{id: actor_found_id} | tail] = Actors.find_local_by_username("tcit")
      %Actor{id: actor2_found_id} = hd(tail)
      assert MapSet.new([actor_found_id, actor2_found_id]) == MapSet.new([actor.id, actor2.id])
    end

    test "test find_and_count_actors_by_username_or_name/4 returns actors with similar usernames",
         %{
           actor: %Actor{id: actor_id}
         } do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        with {:ok, %Actor{id: actor2_id}} <- Actors.get_or_fetch_by_url(@remote_account_url) do
          %{total: 2, elements: actors} =
            Actors.find_and_count_actors_by_username_or_name("tcit", [:Person])

          actors_ids = actors |> Enum.map(& &1.id)

          assert MapSet.new(actors_ids) == MapSet.new([actor2_id, actor_id])
        end
      end
    end

    test "test find_and_count_actors_by_username_or_name/4 returns actors with similar names" do
      %{total: 0, elements: actors} =
        Actors.find_and_count_actors_by_username_or_name("ohno", [:Person])

      assert actors == []
    end

    test "test get_public_key_for_url/1 with local actor", %{actor: actor} do
      assert Actor.get_public_key_for_url(actor.url) ==
               actor.keys |> Mobilizon.Actors.Actor.prepare_public_key()
    end

    @remote_actor_key {:ok,
                       {:RSAPublicKey,
                        20_890_513_599_005_517_665_557_846_902_571_022_168_782_075_040_010_449_365_706_450_877_170_130_373_892_202_874_869_873_999_284_399_697_282_332_064_948_148_602_583_340_776_692_090_472_558_740_998_357_203_838_580_321_412_679_020_304_645_826_371_196_718_081_108_049_114_160_630_664_514_340_729_769_453_281_682_773_898_619_827_376_232_969_899_348_462_205_389_310_883_299_183_817_817_999_273_916_446_620_095_414_233_374_619_948_098_516_821_650_069_821_783_810_210_582_035_456_563_335_930_330_252_551_528_035_801_173_640_288_329_718_719_895_926_309_416_142_129_926_226_047_930_429_802_084_560_488_897_717_417_403_272_782_469_039_131_379_953_278_833_320_195_233_761_955_815_307_522_871_787_339_192_744_439_894_317_730_207_141_881_699_363_391_788_150_650_217_284_777_541_358_381_165_360_697_136_307_663_640_904_621_178_632_289_787,
                        65_537}}
    test "test get_public_key_for_url/1 with remote actor" do
      use_cassette "actors/remote_actor_mastodon_tcit" do
        assert Actor.get_public_key_for_url(@remote_account_url) == @remote_actor_key
      end
    end

    test "test get_public_key_for_url/1 with remote actor and bad key" do
      use_cassette "actors/remote_actor_mastodon_tcit_actor_deleted" do
        assert Actor.get_public_key_for_url(@remote_account_url) == {:error, :actor_fetch_error}
      end
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

    test "update_actor/2 with valid data updates the actor", %{actor: actor} do
      assert {:ok, actor} = Actors.update_actor(actor, @update_attrs)
      assert %Actor{} = actor
      assert actor.summary == "some updated description"
      assert actor.name == "some updated name"
      assert actor.domain == "some updated domain"
      assert actor.keys == "some updated keys"
      refute actor.suspended
      assert actor.preferred_username == "some updated username"
    end

    test "update_actor/2 with invalid data returns error changeset", %{actor: actor} do
      assert {:error, %Ecto.Changeset{}} = Actors.update_actor(actor, @invalid_attrs)
      actor_fetched = Actors.get_actor!(actor.id)
      assert actor = actor_fetched
    end

    test "delete_actor/1 deletes the actor", %{actor: actor} do
      assert {:ok, %Actor{}} = Actors.delete_actor(actor)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_actor!(actor.id) end
    end

    test "change_actor/1 returns a actor changeset", %{actor: actor} do
      assert %Ecto.Changeset{} = Actors.change_actor(actor)
    end
  end

  describe "groups" do
    alias Mobilizon.Actors
    alias Mobilizon.Actors.Actor

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
      assert {:ok, %Actor{} = group} = Actors.create_group(@valid_attrs)
      assert group.summary == "some description"
      refute group.suspended
      assert group.preferred_username == "some-title"
    end

    test "create_group/1 with an existing profile username fails" do
      _actor = insert(:actor, preferred_username: @valid_attrs.preferred_username)

      assert {:error,
              %Ecto.Changeset{errors: [preferred_username: {"Username is already taken", []}]}} =
               Actors.create_group(@valid_attrs)
    end

    test "create_group/1 with an existing group username fails" do
      assert {:ok, %Actor{} = group} = Actors.create_group(@valid_attrs)

      assert {:error,
              %Ecto.Changeset{errors: [preferred_username: {"Username is already taken", []}]}} =
               Actors.create_group(@valid_attrs)
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actors.create_group(@invalid_attrs)
    end
  end

  alias Mobilizon.Actors

  describe "bots" do
    alias Mobilizon.Actors.Bot

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
      with {:error, %Ecto.Changeset{}} <- Actors.create_bot(@invalid_attrs) do
        assert true
      else
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

    test "change_bot/1 returns a bot changeset" do
      bot = insert(:bot)
      assert %Ecto.Changeset{} = Actors.change_bot(bot)
    end
  end

  describe "followers" do
    alias Mobilizon.Actors.Follower
    alias Mobilizon.Actors.Actor

    @valid_attrs %{approved: true, score: 42}
    @update_attrs %{approved: false, score: 43}
    @invalid_attrs %{approved: nil, score: nil}

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
      assert follower.score == 42

      assert [target_actor] = Actor.get_followings(actor)
      assert [actor] = Actor.get_followers(target_actor)
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
      assert follower.score == 43
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

    test "change_follower/1 returns a follower changeset", context do
      follower = create_test_follower(context)
      assert %Ecto.Changeset{} = Actors.change_follower(follower)
    end

    test "follow/3 makes an actor follow another", %{actor: actor, target_actor: target_actor} do
      # Preloading followers/followings
      actor = Actors.get_actor_with_everything(actor.id)
      target_actor = Actors.get_actor_with_everything(target_actor.id)

      {:ok, follower} = Actor.follow(target_actor, actor)
      assert follower.actor.id == actor.id

      # Referesh followers/followings
      actor = Actors.get_actor_with_everything(actor.id)
      target_actor = Actors.get_actor_with_everything(target_actor.id)

      assert target_actor.followers |> Enum.map(& &1.actor_id) == [actor.id]
      assert actor.followings |> Enum.map(& &1.target_actor_id) == [target_actor.id]

      # Test if actor is already following target actor
      {:error, msg} = Actor.follow(target_actor, actor)
      assert msg =~ "already following"

      # Test if target actor is suspended
      target_actor = %{target_actor | suspended: true}
      {:error, msg} = Actor.follow(target_actor, actor)
      assert msg =~ "suspended"
    end
  end

  describe "members" do
    alias Mobilizon.Actors.Member
    alias Mobilizon.Actors.Actor

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

      assert [group] = Actor.get_groups_member_of(actor)
      assert [actor] = Actor.get_members_for_group(group)
    end

    test "create_member/1 with valid data but same actors fails to create a member", %{
      actor: actor,
      group: group
    } do
      create_test_member(%{actor: actor, group: group})

      valid_attrs =
        @valid_attrs
        |> Map.put(:actor_id, actor.id)
        |> Map.put(:parent_id, group.id)

      assert {:error, _member} = Actors.create_member(valid_attrs)
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

    test "change_member/1 returns a member changeset", context do
      member = create_test_member(context)
      assert %Ecto.Changeset{} = Actors.change_member(member)
    end
  end
end
