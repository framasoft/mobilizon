# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.FormatterTest do
  alias Mobilizon.Service.Formatter
  use Mobilizon.DataCase

  import Mobilizon.Factory

  describe ".add_hashtag_links" do
    test "turns hashtags into links" do
      text = "I love #cofe and #2hu"

      expected_text =
        "I love <a class=\"hashtag\" data-tag=\"cofe\" href=\"http://mobilizon.test/tag/cofe\" rel=\"tag ugc\">#cofe</a> and <a class=\"hashtag\" data-tag=\"2hu\" href=\"http://mobilizon.test/tag/2hu\" rel=\"tag ugc\">#2hu</a>"

      assert {^expected_text, [], _tags} = Formatter.linkify(text)
    end

    test "does not turn html characters to tags" do
      text = "#fact_3: pleroma does what mastodon't"

      expected_text =
        "<a class=\"hashtag\" data-tag=\"fact_3\" href=\"http://mobilizon.test/tag/fact_3\" rel=\"tag ugc\">#fact_3</a>: pleroma does what mastodon't"

      assert {^expected_text, [], _tags} = Formatter.linkify(text)
    end
  end

  describe ".add_links" do
    test "turning urls into links" do
      text = "Hey, check out https://www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla ."

      expected =
        "Hey, check out <a href=\"https://www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla</a> ."

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://mastodon.social/@lambadalambda"

      expected =
        "<a href=\"https://mastodon.social/@lambadalambda\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://mastodon.social/@lambadalambda</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://mastodon.social:4000/@lambadalambda"

      expected =
        "<a href=\"https://mastodon.social:4000/@lambadalambda\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://mastodon.social:4000/@lambadalambda</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "@lambadalambda"
      expected = "@lambadalambda"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "http://www.cs.vu.nl/~ast/intel/"

      expected =
        "<a href=\"http://www.cs.vu.nl/~ast/intel/\" target=\"_blank\" rel=\"noopener noreferrer ugc\">http://www.cs.vu.nl/~ast/intel/</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://forum.zdoom.org/viewtopic.php?f=44&t=57087"

      expected =
        "<a href=\"https://forum.zdoom.org/viewtopic.php?f=44&t=57087\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://forum.zdoom.org/viewtopic.php?f=44&t=57087</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul"

      expected =
        "<a href=\"https://en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://www.google.co.jp/search?q=Nasim+Aghdam"

      expected =
        "<a href=\"https://www.google.co.jp/search?q=Nasim+Aghdam\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://www.google.co.jp/search?q=Nasim+Aghdam</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://en.wikipedia.org/wiki/Duff's_device"

      expected =
        "<a href=\"https://en.wikipedia.org/wiki/Duff's_device\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://en.wikipedia.org/wiki/Duff's_device</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "https://pleroma.com https://pleroma.com/sucks"

      expected =
        "<a href=\"https://pleroma.com\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://pleroma.com</a> <a href=\"https://pleroma.com/sucks\" target=\"_blank\" rel=\"noopener noreferrer ugc\">https://pleroma.com/sucks</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text = "xmpp:contact@hacktivis.me"

      expected =
        "<a href=\"xmpp:contact@hacktivis.me\" target=\"_blank\" rel=\"noopener noreferrer ugc\">xmpp:contact@hacktivis.me</a>"

      assert {^expected, [], []} = Formatter.linkify(text)

      text =
        "magnet:?xt=urn:btih:7ec9d298e91d6e4394d1379caf073c77ff3e3136&tr=udp%3A%2F%2Fopentor.org%3A2710&tr=udp%3A%2F%2Ftracker.blackunicorn.xyz%3A6969&tr=udp%3A%2F%2Ftracker.ccc.de%3A80&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=wss%3A%2F%2Ftracker.btorrent.xyz&tr=wss%3A%2F%2Ftracker.fastcast.nz&tr=wss%3A%2F%2Ftracker.openwebtorrent.com"

      expected =
        "<a href=\"#{text}\" target=\"_blank\" rel=\"noopener noreferrer ugc\">#{text}</a>"

      assert {^expected, [], []} = Formatter.linkify(text)
    end
  end

  describe "add_user_links" do
    test "gives a replacement for user links, using local nicknames in user links text" do
      text = "@gsimg According to @archa_eme_, that is @daggsy. Also hello @archaeme@archae.me"
      gsimg = insert(:actor, preferred_username: "gsimg")

      archaeme =
        insert(:actor, preferred_username: "archa_eme_", url: "https://archeme/@archa_eme_")

      archaeme_remote = insert(:actor, preferred_username: "archaeme", domain: "archae.me")

      {text, mentions, []} = Formatter.linkify(text)

      assert length(mentions) == 3

      expected_text =
        "<span class=\"h-card mention\" data-user=\"#{gsimg.id}\">@<span>gsimg</span></span> According to <span class=\"h-card mention\" data-user=\"#{
          archaeme.id
        }\">@<span>archa_eme_</span></span>, that is @daggsy. Also hello <span class=\"h-card mention\" data-user=\"#{
          archaeme_remote.id
        }\">@<span>archaeme</span></span>"

      assert expected_text == text
    end

    test "gives a replacement for single-character local nicknames" do
      text = "@o hi"
      o = insert(:actor, preferred_username: "o")

      {text, mentions, []} = Formatter.linkify(text)

      assert length(mentions) == 1

      expected_text =
        "<span class=\"h-card mention\" data-user=\"#{o.id}\">@<span>o</span></span> hi"

      assert expected_text == text
    end

    test "does not give a replacement for single-character local nicknames who don't exist" do
      text = "@a hi"

      expected_text = "@a hi"
      assert {^expected_text, [] = _mentions, [] = _tags} = Formatter.linkify(text)
    end
  end

  describe ".parse_tags" do
    test "parses tags in the text" do
      text = "Here's a #Test. Maybe these are #working or not. What about #漢字? And #は｡"

      expected_tags = [
        {"#Test", "test"},
        {"#working", "working"},
        {"#は", "は"},
        {"#漢字", "漢字"}
      ]

      assert {_text, [], ^expected_tags} = Formatter.linkify(text)
    end

    test "parses tags in HTML" do
      text = "<p><i>Hello #there</i></p>"

      assert {_text, [], [{"#there", "there"}]} = Formatter.linkify(text)
    end
  end

  test "it can parse mentions and return the relevant users" do
    text =
      "@@gsimg According to @archaeme, that is @daggsy. Also hello @archaeme@archae.me and @o and @@@jimm"

    o = insert(:actor, preferred_username: "o")
    # jimm = insert(:actor, preferred_username: "jimm")
    # gsimg = insert(:actor, preferred_username: "gsimg")
    archaeme = insert(:actor, preferred_username: "archaeme")
    archaeme_remote = insert(:actor, preferred_username: "archaeme", domain: "archae.me")

    expected_mentions = [
      {"@archaeme", archaeme.id},
      {"@archaeme@archae.me", archaeme_remote.id},
      # TODO: Debug me
      # {"@gsimg", gsimg.id},
      # {"@jimm", jimm.id},
      {"@o", o.id}
    ]

    {_text, mentions, []} = Formatter.linkify(text)

    assert expected_mentions ==
             Enum.map(mentions, fn {username, actor} -> {username, actor.id} end)
  end

  test "it escapes HTML in plain text" do
    text = "hello & world google.com/?a=b&c=d \n http://test.com/?a=b&c=d 1"
    expected = "hello &amp; world google.com/?a=b&c=d \n http://test.com/?a=b&c=d 1"

    assert Formatter.html_escape(text, "text/plain") == expected
  end
end
