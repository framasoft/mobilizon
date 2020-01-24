# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MobilizonWeb.Plugs.MappedSignatureToIdentityTest do
  use MobilizonWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias MobilizonWeb.Plugs.MappedSignatureToIdentity

  defp set_signature(conn, key_id) do
    conn
    |> put_req_header("signature", "keyId=\"#{key_id}\"")
    |> assign(:valid_signature, true)
  end

  test "it successfully maps a valid identity with a valid signature" do
    use_cassette "activity_pub/signature/valid" do
      conn =
        build_conn(:get, "/doesntmattter")
        |> set_signature("https://framapiaf.org/users/admin")
        |> MappedSignatureToIdentity.call(%{})

      refute is_nil(conn.assigns.actor)
    end
  end

  test "it successfully maps a valid identity with a valid signature with payload" do
    use_cassette "activity_pub/signature/valid_payload" do
      conn =
        build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
        |> set_signature("https://framapiaf.org/users/admin")
        |> MappedSignatureToIdentity.call(%{})

      refute is_nil(conn.assigns.actor)
    end
  end

  test "it considers a mapped identity to be invalid when it mismatches a payload" do
    use_cassette "activity_pub/signature/invalid_payload" do
      conn =
        build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
        |> set_signature("https://niu.moe/users/rye")
        |> MappedSignatureToIdentity.call(%{})

      assert %{valid_signature: false} == conn.assigns
    end
  end

  test "it considers a mapped identity to be invalid when the identity cannot be found" do
    use_cassette "activity_pub/signature/invalid_not_found" do
      conn =
        build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
        |> set_signature("http://niu.moe/users/rye")
        |> MappedSignatureToIdentity.call(%{})

      assert %{valid_signature: false} == conn.assigns
    end
  end
end
