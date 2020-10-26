# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/upload_test.ex

defmodule Mobilizon.UploadTest do
  use Mobilizon.DataCase

  alias Mobilizon.Config

  alias Mobilizon.Web.{Endpoint, Upload}
  alias Mobilizon.Web.Upload.Uploader

  describe "Storing a file with the Local uploader" do
    setup [:ensure_local_uploader]

    test "returns a media url" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "image.jpg"
      }

      {:ok, data} = Upload.store(file)

      assert %{
               url: url,
               content_type: "image/jpeg",
               size: 13_227
             } = data

      assert String.starts_with?(url, Endpoint.url() <> "/media/")
    end

    test "returns a media url with configured base_url" do
      base_url = "https://cache.mobilizon.social"

      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "image.jpg"
      }

      {:ok, data} = Upload.store(file, base_url: base_url)

      assert String.starts_with?(data.url, base_url <> "/media/")
    end

    test "copies the file to the configured folder with deduping" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image.jpg"
      }

      {:ok, data} = Upload.store(file, filters: [Upload.Filter.Dedupe])

      assert data.url ==
               Endpoint.url() <>
                 "/media/590523d60d3831ec92d05cdd871078409d5780903910efec5cd35ab1b0f19d11.jpg"
    end

    test "copies the file to the configured folder without deduping" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image.jpg"
      }

      {:ok, data} = Upload.store(file)
      assert data.name == "an [image.jpg"
    end

    test "fixes incorrect content type" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "application/octet-stream",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image.jpg"
      }

      {:ok, data} = Upload.store(file, filters: [Upload.Filter.Dedupe])
      assert data.content_type == "image/jpeg"
    end

    test "adds missing extension" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image"
      }

      {:ok, data} = Upload.store(file)
      assert data.name == "an [image.jpg"
    end

    test "fixes incorrect file extension" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image.blah"
      }

      {:ok, data} = Upload.store(file)
      assert data.name == "an [image.jpg"
    end

    test "doesn't allow uploading with unknown type" do
      File.cp("test/fixtures/test.txt", "test/fixtures/test_tmp.txt")

      file = %Plug.Upload{
        content_type: "text/plain",
        path: Path.absname("test/fixtures/test_tmp.txt"),
        filename: "test.txt"
      }

      assert {:error, :mime_type_not_allowed} == Upload.store(file)
    end

    test "copies the file to the configured folder with anonymizing filename" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an [image.jpg"
      }

      {:ok, data} = Upload.store(file, filters: [Upload.Filter.AnonymizeFilename])

      refute data.name == "an [image.jpg"
    end

    test "escapes invalid characters in url" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: "an… image.jpg"
      }

      {:ok, data} = Upload.store(file)

      assert Path.basename(data.url) == "an%E2%80%A6%20image.jpg"
    end

    test "escapes reserved uri characters" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

      file = %Plug.Upload{
        content_type: "image/jpg",
        path: Path.absname("test/fixtures/image_tmp.jpg"),
        filename: ":?#[]@!$&\\'()*+,;=.jpg"
      }

      {:ok, data} = Upload.store(file)

      assert Path.basename(data.url) ==
               "%3A%3F%23%5B%5D%40%21%24%26%5C%27%28%29%2A%2B%2C%3B%3D.jpg"
    end

    test "upload and delete successfully a file" do
      {path, url} = upload()
      assert File.exists?(path)
      assert {:ok, _} = Upload.remove(url)
      refute File.exists?(path)
      path = path |> Path.split() |> Enum.reverse() |> tl |> Enum.reverse() |> Path.join()
      refute File.exists?(path)
    end

    test "delete a not existing file" do
      file =
        Config.get!([Uploader.Local, :uploads]) <>
          "/not_existing/definitely.jpg"

      refute File.exists?(file)

      assert {:error, "File not_existing/definitely.jpg doesn't exist"} =
               Upload.remove("https://mobilizon.test/media/not_existing/definitely.jpg")
    end
  end

  defp upload do
    File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

    file = %Plug.Upload{
      content_type: "image/jpg",
      path: Path.absname("test/fixtures/image_tmp.jpg"),
      filename: "image.jpg"
    }

    {:ok, data} = Upload.store(file)

    assert %{
             url: url,
             size: 13_227,
             content_type: "image/jpeg"
           } = data

    assert String.starts_with?(url, Endpoint.url() <> "/media/")

    %URI{path: "/media/" <> path} = URI.parse(url)
    {Config.get!([Uploader.Local, :uploads]) <> "/" <> path, url}
  end
end
