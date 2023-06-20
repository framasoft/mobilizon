# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/web_finger/web_finger_test.exs

defmodule Mobilizon.Web.ExportControllerTest do
  use Mobilizon.Web.ConnCase

  test "GET /.well-known/webfinger with no query", %{conn: conn} do
    conn = get(conn, "/exports/not_existing/whatever")
    assert response(conn, 404) == "Export to format not_existing is not enabled on this instance"
  end
end
