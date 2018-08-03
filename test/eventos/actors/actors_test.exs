defmodule Eventos.ActorsTest do
  use Eventos.DataCase
  import Eventos.Factory

  alias Eventos.Actors

  describe "actors" do
    alias Eventos.Actors.Actor

    @valid_attrs %{
      summary: "some description",
      name: "some name",
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
      preferred_username: nil
    }

    setup do
      user = insert(:user)
      actor = insert(:actor, user: user)

      {:ok, actor: actor}
    end

    test "list_actors/0 returns all actors", %{actor: actor} do
      actors = Actors.list_actors()
      assert actors = [actor]
    end

    test "get_actor!/1 returns the actor with given id", %{actor: actor} do
      actor_fetched = Actors.get_actor!(actor.id)
      assert actor_fetched = actor
    end

    test "get_actor_with_everything!/1 returns the actor with it's organized events", %{
      actor: actor
    } do
      assert Actors.get_actor_with_everything!(actor.id).organized_events == []
      event = insert(:event, organizer_actor: actor)
      events = Actors.get_actor_with_everything!(actor.id).organized_events
      assert events = [event]
    end

    test "get_actor_by_name/1 returns a local actor", %{actor: actor} do
      actor_found = Actors.get_actor_by_name(actor.preferred_username)
      assert actor_found = actor
    end

    test "get_local_actor_by_name_with_everything!/1 returns the local actor with it's organized events", %{
      actor: actor
    } do
      assert Actors.get_local_actor_by_name_with_everything(actor.preferred_username).organized_events == []
      event = insert(:event, organizer_actor: actor)
      events = Actors.get_local_actor_by_name_with_everything(actor.preferred_username).organized_events
      assert events = [event]
    end

    test "get_actor_by_name_with_everything!/1 returns the local actor with it's organized events", %{
      actor: actor
    } do
      assert Actors.get_actor_by_name_with_everything(actor.preferred_username).organized_events == []
      event = insert(:event, organizer_actor: actor)
      events = Actors.get_actor_by_name_with_everything(actor.preferred_username).organized_events
      assert events = [event]
    end

    test "get_or_fetch_by_url/1 returns the local actor for the url", %{
      actor: actor
    } do
      assert Actors.get_or_fetch_by_url(actor.url).preferred_username == actor.preferred_username
      assert Actors.get_or_fetch_by_url(actor.url).domain == nil
    end

    @remote_account_url "https://social.tcit.fr/users/tcit"
    @remote_account_username "tcit"
    @remote_account_domain "social.tcit.fr"
    test "get_or_fetch_by_url/1 returns the remote actor for the url" do
      assert %Actor{preferred_username: @remote_account_username, domain: @remote_account_domain} = Actors.get_or_fetch_by_url(@remote_account_url)
    end

    test "test find_local_by_username/1 returns local actors with similar usernames", %{actor: actor} do
      actor2 = insert(:actor)
      actors = Actors.find_local_by_username("thomas")
      assert actors = [actor, actor2]
    end

    test "test find_actors_by_username/1 returns actors with similar usernames", %{actor: actor} do
      %Actor{} = actor2 = Actors.get_or_fetch_by_url(@remote_account_url)
      actors = Actors.find_actors_by_username("t")
      assert actors = [actor, actor2]
    end

    test "test get_public_key_for_url/1 with local actor", %{actor: actor} do
      assert Actor.get_public_key_for_url(actor.url) == actor.keys |> Eventos.Service.ActivityPub.Utils.pem_to_public_key()
    end

    @remote_actor_key {:RSAPublicKey, 20890513599005517665557846902571022168782075040010449365706450877170130373892202874869873999284399697282332064948148602583340776692090472558740998357203838580321412679020304645826371196718081108049114160630664514340729769453281682773898619827376232969899348462205389310883299183817817999273916446620095414233374619948098516821650069821783810210582035456563335930330252551528035801173640288329718719895926309416142129926226047930429802084560488897717417403272782469039131379953278833320195233761955815307522871787339192744439894317730207141881699363391788150650217284777541358381165360697136307663640904621178632289787, 65537}
    test "test get_public_key_for_url/1 with remote actor" do
      require Logger
      assert Actor.get_public_key_for_url(@remote_account_url) == @remote_actor_key
    end

    test "create_actor/1 with valid data creates a actor" do
      assert {:ok, %Actor{} = actor} = Actors.create_actor(@valid_attrs)
      assert actor.summary == "some description"
      assert actor.name == "some name"
      assert actor.domain == "some domain"
      assert actor.keys == "some keypair"
      assert actor.suspended
      assert actor.preferred_username == "some username"
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

  describe "users" do
    alias Eventos.Actors.{User, Actor}

    @actor_valid_attrs %{
      description: "some description",
      display_name: "some display_name",
      domain: "some domain",
      keys: "some keys",
      suspended: true,
      uri: "some uri",
      url: "some url",
      preferred_username: "some username"
    }
    @valid_attrs %{email: "foo@bar.tld", password: "some password", role: 42}
    @update_attrs %{email: "foo@fighters.tld", password: "some updated password", role: 43}
    @invalid_attrs %{email: nil, password_hash: nil, role: nil}

    def user_fixture(attrs \\ %{}) do
      insert(:user)
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      users = Actors.list_users()
      assert users = [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      user_fetched = Actors.get_user!(user.id)
      assert user_fetched = user
    end

    test "create_user/1 with valid data creates a user" do
      {:ok, %Actor{} = actor} = Actors.create_actor(@actor_valid_attrs)
      attrs = Map.put(@valid_attrs, :actor_id, actor.id)
      assert {:ok, %User{} = user} = Actors.create_user(attrs)
      assert user.email == "foo@bar.tld"
      assert user.role == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actors.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Actors.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "foo@fighters.tld"
      assert user.role == 43
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Actors.update_user(user, @invalid_attrs)
      user_fetched = Actors.get_user!(user.id)
      assert user = user_fetched
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Actors.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Actors.change_user(user)
    end
  end

  describe "groups" do
    alias Eventos.Actors
    alias Eventos.Actors.Actor

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

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actors.create_group(@invalid_attrs)
    end
  end

  alias Eventos.Actors

  describe "bots" do
    alias Eventos.Actors.Bot

    @valid_attrs %{source: "some source", type: "some type"}
    @update_attrs %{source: "some updated source", type: "some updated type"}
    @invalid_attrs %{source: nil, type: nil}

    def bot_fixture(attrs \\ %{}) do
      insert(:bot)
    end

    test "list_bots/0 returns all bots" do
      bot = bot_fixture()
      bots = Actors.list_bots()
      assert bots = [bot]
    end

    test "get_bot!/1 returns the bot with given id" do
      bot = bot_fixture()
      bot_fetched = Actors.get_bot!(bot.id)
      assert bot_fetched = bot
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
      assert {:error, %Ecto.Changeset{}} = Actors.create_bot(@invalid_attrs)
    end

    test "update_bot/2 with valid data updates the bot" do
      bot = bot_fixture()
      assert {:ok, bot} = Actors.update_bot(bot, @update_attrs)
      assert %Bot{} = bot
      assert bot.source == "some updated source"
      assert bot.type == "some updated type"
    end

    test "update_bot/2 with invalid data returns error changeset" do
      bot = bot_fixture()
      assert {:error, %Ecto.Changeset{}} = Actors.update_bot(bot, @invalid_attrs)
      bot_fetched = Actors.get_bot!(bot.id)
      assert bot = bot_fetched
    end

    test "delete_bot/1 deletes the bot" do
      bot = bot_fixture()
      assert {:ok, %Bot{}} = Actors.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_bot!(bot.id) end
    end

    test "change_bot/1 returns a bot changeset" do
      bot = bot_fixture()
      assert %Ecto.Changeset{} = Actors.change_bot(bot)
    end
  end

  describe "followers" do
    alias Eventos.Actors.Follower
    alias Eventos.Actors.Actor

    @valid_attrs %{approved: true, score: 42}
    @update_attrs %{approved: false, score: 43}
    @invalid_attrs %{approved: nil, score: nil}

    setup do
      actor = insert(:actor)
      target_actor = insert(:actor)
      {:ok, actor: actor, target_actor: target_actor}
    end

    defp create_follower(%{actor: actor, target_actor: target_actor}) do
      insert(:follower, actor: actor, target_actor: target_actor)
    end

    test "get_follower!/1 returns the follower with given id", context do
      follower = create_follower(context)
      follower_fetched = Actors.get_follower!(follower.id)
      assert follower_fetched = follower
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

      actor_followings = Actor.get_followings(actor)
      assert actor_followings = [target_actor]
      actor_followers = Actor.get_followers(target_actor)
      assert actor_followers = [actor]
    end

    test "create_follower/1 with valid data but same actors fails to create a follower", %{
      actor: actor,
      target_actor: target_actor
    } do
      create_follower(%{actor: actor, target_actor: target_actor})
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
      follower = create_follower(context)
      assert {:ok, follower} = Actors.update_follower(follower, @update_attrs)
      assert %Follower{} = follower
      assert follower.approved == false
      assert follower.score == 43
    end

    test "update_follower/2 with invalid data returns error changeset", context do
      follower = create_follower(context)
      assert {:error, %Ecto.Changeset{}} = Actors.update_follower(follower, @invalid_attrs)
      follower_fetched = Actors.get_follower!(follower.id)
      assert follower = follower_fetched
    end

    test "delete_follower/1 deletes the follower", context do
      follower = create_follower(context)
      assert {:ok, %Follower{}} = Actors.delete_follower(follower)
      assert_raise Ecto.NoResultsError, fn -> Actors.get_follower!(follower.id) end
    end

    test "change_follower/1 returns a follower changeset", context do
      follower = create_follower(context)
      assert %Ecto.Changeset{} = Actors.change_follower(follower)
    end
  end
end
