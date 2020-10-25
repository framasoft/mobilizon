# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.FilterTest do
  use Mobilizon.DataCase
  use Mobilizon.Tests.Helpers

  alias Mobilizon.Config
  alias Mobilizon.Web.Upload.Filter

  setup do: clear_config([Mobilizon.Web.Upload.Filter.AnonymizeFilename, :text])

  test "applies filters" do
    Config.put([Mobilizon.Web.Upload.Filter.AnonymizeFilename, :text], "custom-file.png")

    File.cp!(
      "test/fixtures/image.jpg",
      "test/fixtures/image_tmp.jpg"
    )

    upload = %Mobilizon.Web.Upload{
      name: "an… image.jpg",
      content_type: "image/jpeg",
      path: Path.absname("test/fixtures/image_tmp.jpg"),
      tempfile: Path.absname("test/fixtures/image_tmp.jpg")
    }

    assert Filter.filter([], upload) == {:ok, upload}

    assert {:ok, upload} = Filter.filter([Mobilizon.Web.Upload.Filter.AnonymizeFilename], upload)
    assert upload.name == "custom-file.png"
  end
end
