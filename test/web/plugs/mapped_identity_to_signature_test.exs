# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.MappedSignatureToIdentityTest do
  use Mobilizon.Web.ConnCase
  import Mox

  alias Mobilizon.Service.HTTP.ActivityPub.Mock
  alias Mobilizon.Web.Plugs.MappedSignatureToIdentity

  defp set_signature(conn, key_id) do
    conn
    |> put_req_header("signature", "keyId=\"#{key_id}\"")
    |> assign(:valid_signature, true)
  end

  defp framapiaf_admin do
    "test/fixtures/signature/framapiaf_admin.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp nyu_rye do
    "test/fixtures/signature/nyu_rye.json"
    |> File.read!()
    |> Jason.decode!()
  end

  test "it successfully maps a valid identity with a valid signature" do
    Mock
    |> expect(:call, fn
      %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: framapiaf_admin()}}
    end)

    Mock
    |> expect(:call, fn
      %{method: :get, url: "/doesntmattter"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: ""}}
    end)

    conn =
      build_conn(:get, "/doesntmattter")
      |> set_signature("https://framapiaf.org/users/admin")
      |> MappedSignatureToIdentity.call(%{})

    refute is_nil(conn.assigns.actor)
  end

  test "it successfully maps a valid identity with a valid signature with payload" do
    Mock
    |> expect(:call, fn
      %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: framapiaf_admin()}}
    end)

    Mock
    |> expect(:call, fn
      %{method: :post, url: "/doesntmattter"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: ""}}
    end)

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://framapiaf.org/users/admin")
      |> MappedSignatureToIdentity.call(%{})

    refute is_nil(conn.assigns.actor)
  end

  test "it considers a mapped identity to be invalid when it mismatches a payload" do
    Mock
    |> expect(:call, fn
      %{method: :get, url: "https://niu.moe/users/rye"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: nyu_rye()}}
    end)

    Mock
    |> expect(:call, fn
      %{method: :post, url: "/doesntmattter"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: ""}}
    end)

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://niu.moe/users/rye")
      |> MappedSignatureToIdentity.call(%{})

    assert %{valid_signature: false} == conn.assigns
  end

  @tag skip: "Available again when lib/web/plugs/mapped_signature_to_identity.ex#62 is fixed"
  test "it considers a mapped identity to be invalid when the identity cannot be found" do
    Mock
    |> expect(:call, fn
      %{method: :get, url: "https://mastodon.social/users/gargron"}, _opts ->
        {:ok, %Tesla.Env{status: 404, body: ""}}
    end)

    Mock
    |> expect(:call, fn
      %{method: :post, url: "/doesntmattter"}, _opts ->
        {:ok, %Tesla.Env{status: 200, body: ""}}
    end)

    conn =
      build_conn(:post, "/doesntmattter", %{"actor" => "https://framapiaf.org/users/admin"})
      |> set_signature("https://mastodon.social/users/gargron")
      |> MappedSignatureToIdentity.call(%{})

    assert %{valid_signature: false} == conn.assigns
  end
end
