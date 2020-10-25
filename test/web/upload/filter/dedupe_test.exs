# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Filter.DedupeTest do
  use Mobilizon.DataCase

  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter.Dedupe

  @shasum "590523d60d3831ec92d05cdd871078409d5780903910efec5cd35ab1b0f19d11"

  test "adds shasum" do
    File.cp!(
      "test/fixtures/image.jpg",
      "test/fixtures/image_tmp.jpg"
    )

    upload = %Upload{
      name: "an… image.jpg",
      content_type: "image/jpeg",
      path: Path.absname("test/fixtures/image_tmp.jpg"),
      tempfile: Path.absname("test/fixtures/image_tmp.jpg")
    }

    assert {
             :ok,
             :filtered,
             %Upload{id: @shasum, path: @shasum <> ".jpg"}
           } = Dedupe.filter(upload)
  end
end
