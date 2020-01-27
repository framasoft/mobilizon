# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.Federating do
  @moduledoc """
  Restrict ActivityPub routes when not federating
  """

  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    if Mobilizon.Config.get([:instance, :federating]) do
      conn
    else
      conn
      |> put_status(404)
      |> Phoenix.Controller.put_view(Mobilizon.Web.ErrorView)
      |> Phoenix.Controller.render("404.json")
      |> halt()
    end
  end
end
