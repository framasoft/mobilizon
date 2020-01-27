# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/plugs/uploaded_media_plug_test.ex

defmodule Mobilizon.Web.Plugs.UploadedMediaPlugTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Web.Upload

  defp upload_file(context) do
    Mobilizon.DataCase.ensure_local_uploader(context)
    File.cp!("test/fixtures/image.jpg", "test/fixtures/image_tmp.jpg")

    file = %Plug.Upload{
      content_type: "image/jpg",
      path: Path.absname("test/fixtures/image_tmp.jpg"),
      filename: "nice_tf.jpg"
    }

    {:ok, data} = Upload.store(file)
    [attachment_url: data.url]
  end

  setup_all :upload_file

  test "does not send Content-Disposition header when name param is not set", %{
    attachment_url: attachment_url
  } do
    conn = get(build_conn(), attachment_url)
    refute Enum.any?(conn.resp_headers, &(elem(&1, 0) == "content-disposition"))
  end

  test "sends Content-Disposition header when name param is set", %{
    attachment_url: attachment_url
  } do
    conn = get(build_conn(), attachment_url <> "?name=\"cofe\".gif")

    assert Enum.any?(
             conn.resp_headers,
             &(&1 == {"content-disposition", "filename=\"\\\"cofe\\\".gif\""})
           )
  end
end
