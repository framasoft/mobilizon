# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Filter.MogrifyTest do
  use Mobilizon.DataCase
  use Mobilizon.Tests.Helpers
  import Mock

  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter

  test "apply mogrify filter" do
    clear_config(Filter.Mogrify, args: [{"tint", "40"}])

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

    task =
      Task.async(fn ->
        assert_receive {:apply_filter, {_, "tint", "40"}}, 4_000
      end)

    with_mock Mogrify,
      open: fn _f -> %Mogrify.Image{} end,
      custom: fn _m, _a -> :ok end,
      custom: fn m, a, o -> send(task.pid, {:apply_filter, {m, a, o}}) end,
      save: fn _f, _o -> :ok end do
      assert Filter.Mogrify.filter(upload) == {:ok, :filtered}
    end

    Task.await(task)
  end
end
