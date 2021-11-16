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
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.HTTPSignatures.Signature

  require Logger

  @spec init(any()) :: any()
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

  @spec actor_from_key_id(Plug.Conn.t()) ::
          {:ok, Actor.t()} | {:error, :actor_not_found | :no_key_in_conn}
  defp actor_from_key_id(conn) do
    Logger.debug("Determining actor from connection signature")

    case key_id_from_conn(conn) do
      key_actor_id when is_binary(key_actor_id) ->
        # We don't need to call refreshment here since
        # the Mobilizon.Federation.HTTPSignatures.Signature plug
        # should already have refreshed the actor if needed
        ActivityPubActor.make_actor_from_url(key_actor_id, ignore_sign_object_fetches: true)

      nil ->
        {:error, :no_key_in_conn}
    end
  end

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(%{assigns: %{actor: _}} = conn, _opts), do: conn

  # if this has payload make sure it is signed by the same actor that made it
  def call(%{assigns: %{valid_signature: true}, params: %{"actor" => actor}} = conn, _opts) do
    with actor_id when actor_id != nil <- Utils.get_url(actor),
         {:ok, %Actor{} = actor} <- actor_from_key_id(conn),
         {:actor_match, true} <- {:actor_match, actor.url == actor_id} do
      Logger.debug("Mapped identity to #{actor.url} from actor param")
      assign(conn, :actor, actor)
    else
      {:actor_match, false} ->
        Logger.debug("Failed to map identity from signature (payload actor mismatch)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}, actor=#{actor}")
        assign(conn, :valid_signature, false)

      {:error, :no_key_in_conn} ->
        Logger.debug("There was no key in conn")
        conn

      # TODO: remove me once testsuite uses mapped capabilities instead of what we do now
      {:error, :actor_not_found} ->
        Logger.debug("Failed to map identity from signature (lookup failure)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}, actor=#{actor}")
        conn
    end
  end

  # no payload, probably a signed fetch
  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    case actor_from_key_id(conn) do
      {:ok, %Actor{} = actor} ->
        Logger.debug("Mapped identity to #{actor.url} from signed fetch")
        assign(conn, :actor, actor)

      {:error, :no_key_in_conn} ->
        Logger.debug("There was no key in conn")
        assign(conn, :valid_signature, false)

      {:error, :actor_not_found} ->
        Logger.debug("Failed to map identity from signature (no payload actor mismatch)")
        Logger.debug("key_id=#{key_id_from_conn(conn)}")
        assign(conn, :valid_signature, false)
    end
  end

  # no signature at all
  def call(conn, _opts), do: conn
end
