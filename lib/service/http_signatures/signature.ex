# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/signature.ex

defmodule Mobilizon.Service.HTTPSignatures.Signature do
  @moduledoc """
  Adapter for the `HTTPSignatures` lib that handles signing and providing public keys to verify HTTPSignatures
  """
  @behaviour HTTPSignatures.Adapter

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  require Logger

  def key_id_to_actor_url(key_id) do
    uri =
      URI.parse(key_id)
      |> Map.put(:fragment, nil)

    uri =
      if not is_nil(uri.path) and String.ends_with?(uri.path, "/publickey") do
        Map.put(uri, :path, String.replace(uri.path, "/publickey", ""))
      else
        uri
      end

    URI.to_string(uri)
  end

  def fetch_public_key(conn) do
    with %{"keyId" => kid} <- HTTPSignatures.signature_for_conn(conn),
         actor_id <- key_id_to_actor_url(kid),
         :ok <- Logger.debug("Fetching public key for #{actor_id}"),
         {:ok, public_key} <- Actor.get_public_key_for_url(actor_id) do
      {:ok, public_key}
    else
      e ->
        {:error, e}
    end
  end

  def refetch_public_key(conn) do
    with %{"keyId" => kid} <- HTTPSignatures.signature_for_conn(conn),
         actor_id <- key_id_to_actor_url(kid),
         :ok <- Logger.debug("Refetching public key for #{actor_id}"),
         {:ok, _actor} <- ActivityPub.make_actor_from_url(actor_id),
         {:ok, public_key} <- Actor.get_public_key_for_url(actor_id) do
      {:ok, public_key}
    else
      e ->
        {:error, e}
    end
  end

  def sign(%Actor{} = actor, headers) do
    Logger.debug("Signing on behalf of #{actor.url}")
    Logger.debug("headers")
    Logger.debug(inspect(headers))

    with {:ok, key} <- actor.keys |> Actor.prepare_public_key() do
      HTTPSignatures.sign(key, actor.url <> "#main-key", headers)
    end
  end

  def generate_date_header(date \\ Timex.now("GMT")) do
    case Timex.format(date, "%a, %d %b %Y %H:%M:%S %Z", :strftime) do
      {:ok, date} ->
        date

      {:error, err} ->
        Logger.error("Unable to generate date header")
        Logger.debug(inspect(err))
        nil
    end
  end

  def generate_request_target(method, path), do: "#{method} #{path}"

  def build_digest(body) do
    "SHA-256=" <> (:crypto.hash(:sha256, body) |> Base.encode64())
  end
end
