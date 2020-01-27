# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.MappedSignatureToIdentity do
  @moduledoc """
  Get actor identity from Signature when handing fetches
  """

  import Plug.Conn

  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.HTTPSignatures.Signature

  require Logger

  def init(options), do: options

  @spec key_id_from_conn(Plug.Conn.t()) :: String.t() | nil
  defp key_id_from_conn(conn) do
    case HTTPSignatures.signature_for_conn(conn) do
      %{"keyId" => key_id} ->
        Signature.key_id_to_actor_url(key_id)

      _ ->
        nil
    end
  end

  @spec actor_from_key_id(Plug.Conn.t()) :: Actor.t() | nil
  defp actor_from_key_id(conn) do
    with key_actor_id when is_binary(key_actor_id) <- key_id_from_conn(conn),
         {:ok, %Actor{} = actor} <- ActivityPub.get_or_fetch_actor_by_url(key_actor_id) do
      actor
    else
      _ ->
        nil
    end
  end

  def call(%{assigns: %{actor: _}} = conn, _opts), do: conn

  # if this has payload make sure it is signed by the same actor that made it
  def call(%{assigns: %{valid_signature: true}, params: %{"actor" => actor}} = conn, _opts) do
    with actor_id <- Utils.get_url(actor),
         {:actor, %Actor{} = actor} <- {:actor, actor_from_key_id(conn)},
         {:actor_match, true} <- {:actor_match, actor.url == actor_id} do
      assign(conn, :actor, actor)
    else
      {:actor_match, false} ->
        Logger.debug("Failed to map identity from signature (payload actor mismatch)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}, actor=#{actor}")
        assign(conn, :valid_signature, false)

      # remove me once testsuite uses mapped capabilities instead of what we do now
      {:actor, nil} ->
        Logger.debug("Failed to map identity from signature (lookup failure)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}, actor=#{actor}")
        conn
    end
  end

  # no payload, probably a signed fetch
  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    case actor_from_key_id(conn) do
      %Actor{} = actor ->
        assign(conn, :actor, actor)

      _ ->
        Logger.debug("Failed to map identity from signature (no payload actor mismatch)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}")
        assign(conn, :valid_signature, false)
    end
  end

  # no signature at all
  def call(conn, _opts), do: conn
end
