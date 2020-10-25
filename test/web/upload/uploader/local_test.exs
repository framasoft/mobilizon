# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Uploader.LocalTest do
  use Mobilizon.DataCase
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Uploader.Local

  describe "get_file/1" do
    test "it returns path to local folder for files" do
      assert Local.get_file("") == {:ok, {:static_dir, "test/uploads"}}
    end
  end

  describe "put_file/1" do
    test "put file to local folder" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")
      file_path = "local_upload/files/image.jpg"

      file = %Upload{
        name: "image.jpg",
        content_type: "image/jpeg",
        path: file_path,
        tempfile: Path.absname("test/fixtures/image_tmp.jpg")
      }

      assert Local.put_file(file) == :ok

      assert [Local.upload_path(), file_path]
             |> Path.join()
             |> File.exists?()
    end
  end

  describe "remove_file/1" do
    test "removes local file" do
      File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")
      file_path = "local_upload/files/image.jpg"

      file = %Upload{
        name: "image.jpg",
        content_type: "image/jpeg",
        path: file_path,
        tempfile: Path.absname("test/fixtures/image_tmp.jpg")
      }

      :ok = Local.put_file(file)
      local_path = Path.join([Local.upload_path(), file_path])
      assert File.exists?(local_path)

      Local.remove_file(file_path)

      refute File.exists?(local_path)
    end
  end
end
