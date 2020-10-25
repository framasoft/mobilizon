# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Filter.AnonymizeFilenameTest do
  use Mobilizon.DataCase
  use Mobilizon.Tests.Helpers

  alias Mobilizon.Config
  alias Mobilizon.Web.Upload

  setup do
    File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

    upload_file = %Upload{
      name: "an… image.jpg",
      content_type: "image/jpeg",
      path: Path.absname("test/fixtures/image_tmp.jpg")
    }

    %{upload_file: upload_file}
  end

  setup do: clear_config([Mobilizon.Web.Upload.Filter.AnonymizeFilename, :text])

  test "it replaces filename on pre-defined text", %{upload_file: upload_file} do
    Config.put([Upload.Filter.AnonymizeFilename, :text], "custom-file.png")
    {:ok, :filtered, %Upload{name: name}} = Upload.Filter.AnonymizeFilename.filter(upload_file)
    assert name == "custom-file.png"
  end

  test "it replaces filename on pre-defined text expression", %{upload_file: upload_file} do
    Config.put([Upload.Filter.AnonymizeFilename, :text], "custom-file.{extension}")
    {:ok, :filtered, %Upload{name: name}} = Upload.Filter.AnonymizeFilename.filter(upload_file)
    assert name == "custom-file.jpg"
  end

  test "it replaces filename on random text", %{upload_file: upload_file} do
    {:ok, :filtered, %Upload{name: name}} = Upload.Filter.AnonymizeFilename.filter(upload_file)
    assert <<_::bytes-size(14)>> <> ".jpg" = name
    refute name == "an… image.jpg"
  end
end
