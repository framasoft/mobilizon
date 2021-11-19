# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/signature.ex

defmodule Mobilizon.Federation.HTTPSignatures.Signature do
  @moduledoc """
  Adapter for the `HTTPSignatures` lib that handles signing and providing public keys to verify HTTPSignatures
  """

  @behaviour HTTPSignatures.Adapter

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor

  require Logger

  @spec key_id_to_actor_url(String.t()) :: String.t()
  def key_id_to_actor_url(key_id) do
    %URI{path: path} =
      uri =
      key_id
      |> URI.parse()
      |> Map.put(:fragment, nil)

    uri =
      if is_nil(path) do
        uri
      else
        %URI{uri | path: String.trim_trailing(path, "/publickey")}
      end

    URI.to_string(uri)
  end

  @doc """
  Convert internal PEM encoded keys to public key format.
  """
  @spec prepare_public_key(String.t()) :: {:ok, tuple} | {:error, :pem_decode_error}
  def prepare_public_key(public_key_code) do
    case :public_key.pem_decode(public_key_code) do
      [public_key_entry] ->
        {:ok, :public_key.pem_entry_decode(public_key_entry)}

      _ ->
        {:error, :pem_decode_error}
    end
  end

  # Gets a public key for a given ActivityPub actor ID (url).
  @spec get_public_key_for_url(String.t()) ::
          {:ok, String.t()}
          | {:error, :actor_not_found | :pem_decode_error}
  defp get_public_key_for_url(url) do
    with {:ok, %Actor{} = actor} <- ActivityPubActor.get_or_fetch_actor_by_url(url) do
      get_actor_public_key(actor)
    end
  end

  @spec get_actor_public_key(Actor.t()) :: {:ok, String.t()} | {:error, :pem_decode_error}
  defp get_actor_public_key(%Actor{keys: keys}) do
    case prepare_public_key(keys) do
      {:ok, public_key} ->
        {:ok, public_key}

      {:error, :pem_decode_error} ->
        Logger.error("Error while decoding PEM")

        {:error, :pem_decode_error}
    end
  end

  @spec fetch_public_key(Plug.Conn.t()) ::
          {:ok, String.t()}
          | {:error, :actor_not_found | :pem_decode_error | :no_signature_in_conn}
  def fetch_public_key(conn) do
    case HTTPSignatures.signature_for_conn(conn) do
      %{"keyId" => kid} ->
        actor_id = key_id_to_actor_url(kid)
        Logger.debug("Fetching public key for #{actor_id}")
        get_public_key_for_url(actor_id)

      _ ->
        {:error, :no_signature_in_conn}
    end
  end

  @spec refetch_public_key(Plug.Conn.t()) ::
          {:ok, String.t()}
          | {:error, :actor_fetch_error | :actor_not_fetchable | :pem_decode_error,
             :actor_is_local}
  def refetch_public_key(conn) do
    %{"keyId" => kid} = HTTPSignatures.signature_for_conn(conn)
    actor_url = key_id_to_actor_url(kid)
    Logger.debug("Refetching public key for #{actor_url}")

    with {:ok, %Actor{} = actor} <-
           ActivityPubActor.make_actor_from_url(actor_url, ignore_sign_object_fetches: true) do
      get_actor_public_key(actor)
    end
  end

  @spec sign(Actor.t(), map()) :: String.t() | {:error, :pem_decode_error} | no_return
  def sign(%Actor{domain: domain, keys: keys} = actor, headers) when is_nil(domain) do
    Logger.debug("Signing a payload on behalf of #{actor.url}")
    Logger.debug("headers")
    Logger.debug(inspect(headers))

    case prepare_public_key(keys) do
      {:ok, key} ->
        HTTPSignatures.sign(key, actor.url <> "#main-key", headers)

      {:error, :pem_decode_error} ->
        raise ArgumentError, message: "Failed to prepare public keys for #{actor.url}"
    end
  end

  def sign(%Actor{url: url}, _) do
    Logger.error("Can't do a signature on remote actor #{url}")
    raise ArgumentError, message: "Can't do a signature on remote actor #{url}"
  end

  @spec generate_date_header :: String.t()
  def generate_date_header, do: generate_date_header(NaiveDateTime.utc_now())

  @spec generate_date_header(NaiveDateTime.t()) :: String.t()
  def generate_date_header(%NaiveDateTime{} = date) do
    # We make sure the format is correct
    # TODO: Remove Timex, as this is the only usage (with parsing)
    Timex.lformat!(date, "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} GMT", "en")
  end

  @spec generate_request_target(String.t(), String.t()) :: String.t()
  def generate_request_target(method, path), do: "#{method} #{path}"

  @spec build_digest(String.t()) :: String.t()
  def build_digest(body) do
    "SHA-256=#{:sha256 |> :crypto.hash(body) |> Base.encode64()}"
  end
end
