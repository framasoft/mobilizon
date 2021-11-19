# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.MappedSignatureToIdentityTest do
  use Mobilizon.Web.ConnCase
  import Mobilizon.Factory

  alias Mobilizon.Web.Plugs.MappedSignatureToIdentity

  defp set_signature(conn, key_id) do
    conn
    |> put_req_header("signature", "keyId=\"#{key_id}\"")
    |> assign(:valid_signature, true)
  end

  test "it successfully maps a valid identity with a valid signature" do
    insert(:actor, domain: "framapiaf.org", url: "https://framapiaf.org/users/admin")

    conn =
      build_conn(:get, "/doesntmattter")
      |> set_signature("https://framapiaf.org/users/admin")
      |> MappedSignatureToIdentity.call(%{})

    refute is_nil(conn.assigns.actor)
  end

  test "it successfully maps a valid identity with a valid signature with payload" do
    insert(:actor, domain: "framapiaf.org", url: "https://framapiaf.org/users/admin")

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://framapiaf.org/users/admin")
      |> MappedSignatureToIdentity.call(%{})

    refute is_nil(conn.assigns.actor)
  end

  test "it considers a mapped identity to be invalid when it mismatches a payload" do
    insert(:actor, domain: "framapiaf.org", url: "https://framapiaf.org/users/admin")
    insert(:actor, domain: "niu.moe", url: "https://niu.moe/users/rye")

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://niu.moe/users/rye")
      |> MappedSignatureToIdentity.call(%{})

    assert %{valid_signature: false} == conn.assigns
  end

  test "it considers a mapped identity to be invalid when the identity cannot be found" do
    insert(:actor, domain: "framapiaf.org", url: "https://framapiaf.org/users/admin")
    insert(:actor, domain: "mastodon.social", url: "https://mastodon.social/users/gargron")

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://mastodon.social/users/gargron")
      |> MappedSignatureToIdentity.call(%{})

    assert %{valid_signature: false} == conn.assigns
  end
end
