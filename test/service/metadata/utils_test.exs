defmodule Mobilizon.Service.Metadata.UtilsTest do
  alias Mobilizon.Service.Metadata.Utils
  use Mobilizon.DataCase

  describe "process_description/3" do
    test "process_description/3 strip tags" do
      assert Utils.process_description("<p>This is my biography</p>") == "This is my biography"
    end

    test "process_description/3 cuts after a limit" do
      assert Utils.process_description("<p>This is my biography</p>", "fr", 10) ==
               "This is my…"
    end

    test "process_description/3 cuts after the default limit" do
      assert Utils.process_description(
               "<h1>Biography</h1><p>It all started when someone wanted a <b>very long string</b> to be cut. However it's difficult to invent things to write when you've got nothing to say. Anyway, what's the deal here. We just need to reach 200 characters.",
               "fr"
             ) ==
               "Biography It all started when someone wanted a very long string to be cut. However it's difficult to invent things to write when you've got nothing to say. Anyway, what's the deal here. We just need to…"
    end

    test "process_description/3 returns default if no description is provided" do
      assert Utils.process_description(nil) ==
               "The event organizer didn't add any description."

      assert Utils.process_description("", "en") ==
               "The event organizer didn't add any description."
    end
  end

  describe "default_description/1" do
    test "returns default description with a correct locale" do
      assert Utils.default_description("en") == "The event organizer didn't add any description."
    end

    test "returns default description with no locale provided" do
      assert Utils.default_description() == "The event organizer didn't add any description."
    end
  end

  describe "stringify_tags/1" do
    test "converts tags to string" do
      alias Phoenix.HTML.Tag

      tag_1 = Tag.tag(:meta, property: "og:url", content: "one")
      tag_2 = "<meta content=\"two\" property=\"og:url\">"
      tag_3 = Tag.tag(:meta, property: "og:url", content: "three")

      assert Utils.stringify_tags([tag_1, tag_2, tag_3]) ==
               "<meta content=\"one\" property=\"og:url\"><meta content=\"two\" property=\"og:url\"><meta content=\"three\" property=\"og:url\">"
    end
  end

  describe "strip_tags/1" do
    test "removes tags from string" do
      assert Utils.strip_tags("<h1>Hello</h1><p>How are you</p>") == "Hello How are you"
    end
  end
end
