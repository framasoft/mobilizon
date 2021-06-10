# Portions of this file are derived from Pleroma:
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/-/blob/develop/test/pleroma/upload/filter/analyze_metadata_test.exs

defmodule Mobilizon.Web.Upload.Filter.AnalyzeMetadataTest do
  use Mobilizon.DataCase, async: true
  alias Mobilizon.Web.Upload.Filter.AnalyzeMetadata

  test "adds the image dimensions" do
    upload = %Mobilizon.Web.Upload{
      name: "an… image.jpg",
      content_type: "image/jpeg",
      path: Path.absname("test/fixtures/image.jpg"),
      tempfile: Path.absname("test/fixtures/image.jpg")
    }

    assert {:ok, :filtered, %{width: 266, height: 67}} = AnalyzeMetadata.filter(upload)
  end
end
