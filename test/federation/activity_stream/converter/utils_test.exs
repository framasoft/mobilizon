defmodule Mobilizon.Federation.ActivityStream.Converter.UtilsTest do
  @moduledoc """
  Module to test converting from EventMetadata to AS
  """
  use Mobilizon.DataCase
  import Mobilizon.Factory
  alias Mobilizon.Federation.ActivityStream.Converter.Utils

  describe "get_medias/1" do
    test "getting banner from Document attachment" do
      data =
        File.read!("test/fixtures/mobilizon-post-activity-media.json")
        |> Jason.decode!()
        |> Map.get("object")

      assert Utils.get_medias(data) ==
               {%{
                  "blurhash" => "U5SY?Z00nOxu7ORP.8-pU^kVS#NGXyxbMxM{",
                  "mediaType" => "image/png",
                  "name" => nil,
                  "type" => "Document",
                  "url" => "https://mobilizon.fr/some-image"
                }, []}
    end

    test "getting banner from image property" do
      data =
        File.read!("test/fixtures/mobilizon-post-activity-media-1.json")
        |> Jason.decode!()
        |> Map.get("object")

      assert Utils.get_medias(data) ==
               {%{
                  "blurhash" => "U5SY?Z00nOxu7ORP.8-pU^kVS#NGXyxbMxM{",
                  "mediaType" => "image/png",
                  "name" => nil,
                  "type" => "Image",
                  "url" => "https://mobilizon.fr/some-image-1"
                },
                [
                  %{
                    "blurhash" => "U5SY?Z00nOxu7ORP.8-pU^kVS#NGXyxbMxM{",
                    "mediaType" => "image/png",
                    "name" => nil,
                    "type" => "Document",
                    "url" => "https://mobilizon.fr/some-image"
                  }
                ]}
    end

    test "getting banner from attachment named \"Banner\"" do
      data =
        File.read!("test/fixtures/mobilizon-post-activity-media-2.json")
        |> Jason.decode!()
        |> Map.get("object")

      assert Utils.get_medias(data) ==
               {%{
                  "blurhash" => "U5SY?Z00nOxu7ORP.8-pU^kVS#NGXyxbMxM{",
                  "mediaType" => "image/png",
                  "name" => "Banner",
                  "type" => "Document",
                  "url" => "https://mobilizon.fr/some-image-2"
                },
                [
                  %{
                    "blurhash" => "U5SY?Z00nOxu7ORP.8-pU^kVS#NGXyxbMxM{",
                    "mediaType" => "image/png",
                    "name" => nil,
                    "type" => "Document",
                    "url" => "https://mobilizon.fr/some-image-1"
                  }
                ]}
    end
  end
end
