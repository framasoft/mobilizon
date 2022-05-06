defmodule Mobilizon.ActorTest do
  use Mobilizon.DataCase
  alias Mobilizon.Actors.Actor

  describe "display_name_and_username/1" do
    test "returns correctly if everything is given" do
      assert "hello (@someone@remote.tld)" ==
               Actor.display_name_and_username(%Actor{
                 name: "hello",
                 domain: "remote.tld",
                 preferred_username: "someone"
               })
    end

    test "returns for a local actor" do
      assert "hello (@someone)" ==
               Actor.display_name_and_username(%Actor{
                 name: "hello",
                 domain: nil,
                 preferred_username: "someone"
               })

      assert "hello (@someone)" ==
               Actor.display_name_and_username(%Actor{
                 name: "hello",
                 domain: "",
                 preferred_username: "someone"
               })
    end

    test "returns nil if the name is all that's given" do
      assert nil == Actor.display_name_and_username(%Actor{name: "hello"})
    end

    test "returns with just the username if that's all that's given" do
      assert "someone" ==
               Actor.display_name_and_username(%Actor{preferred_username: "someone"})
    end

    test "returns an appropriate name for a Mobilizon instance actor" do
      assert "My Mobilizon Instance (remote.tld)" ==
               Actor.display_name_and_username(%Actor{
                 name: "My Mobilizon Instance",
                 domain: "remote.tld",
                 preferred_username: "relay",
                 type: :Application
               })
    end

    test "returns an appropriate name for a Mastodon instance actor" do
      assert "remote.tld" ==
               Actor.display_name_and_username(%Actor{
                 name: nil,
                 domain: "remote.tld",
                 preferred_username: "remote.tld",
                 type: :Application
               })
    end
  end

  describe "display_name/1" do
    test "with name" do
      assert "hello" == Actor.display_name(%Actor{preferred_username: "someone", name: "hello"})
    end

    test "without name" do
      assert "someone" == Actor.display_name(%Actor{preferred_username: "someone"})
    end
  end
end
