# https://tools.ietf.org/html/draft-cavage-http-signatures-08
defmodule Mobilizon.Service.HTTPSignatures do
  @moduledoc """
  # HTTP Signatures

  Generates and checks HTTP Signatures
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  import Logger

  def split_signature(sig) do
    default = %{"headers" => "date"}

    sig =
      sig
      |> String.trim()
      |> String.split(",")
      |> Enum.reduce(default, fn part, acc ->
        [key | rest] = String.split(part, "=")
        value = Enum.join(rest, "=")
        Map.put(acc, key, String.trim(value, "\""))
      end)

    Map.put(sig, "headers", String.split(sig["headers"], ~r/\s/))
  end

  def validate(headers, signature, public_key) do
    sigstring = build_signing_string(headers, signature["headers"])

    Logger.debug(fn ->
      "Signature: #{signature["signature"]}"
    end)

    Logger.debug(fn ->
      "Sigstring: #{sigstring}"
    end)

    {:ok, sig} = Base.decode64(signature["signature"])
    :public_key.verify(sigstring, :sha256, sig, public_key)
  end

  defp prepare_public_key(public_key_code) do
    with [public_key_entry] <- :public_key.pem_decode(public_key_code) do
      {:ok, :public_key.pem_entry_decode(public_key_entry)}
    else
      _err ->
        {:error, :pem_decode_error}
    end
  end

  def validate_conn(conn) do
    # TODO: How to get the right key and see if it is actually valid for that request.
    # For now, fetch the key for the actor.
    with {:ok, public_key} <- conn.params["actor"] |> Actor.get_public_key_for_url(),
         {:ok, public_key} <- prepare_public_key(public_key) do
      if validate_conn(conn, public_key) do
        true
      else
        Logger.info("Could not validate request, re-fetching user and trying one more time")
        # Fetch user anew and try one more time
        with actor_id <- conn.params["actor"],
             {:ok, _actor} <- ActivityPub.make_actor_from_url(actor_id),
             {:ok, public_key} <- actor_id |> Actor.get_public_key_for_url(),
             {:ok, public_key} <- prepare_public_key(public_key) do
          validate_conn(conn, public_key)
        end
      end
    else
      e ->
        Logger.debug("Could not found url for actor!")
        Logger.debug(inspect(e))
        false
    end
  end

  def validate_conn(conn, public_key) do
    headers = Enum.into(conn.req_headers, %{})
    host_without_port = String.split(headers["host"], ":") |> hd
    headers = Map.put(headers, "host", host_without_port)
    signature = split_signature(headers["signature"])
    validate(headers, signature, public_key)
  end

  def build_signing_string(headers, used_headers) do
    used_headers
    |> Enum.map(fn header -> "#{header}: #{headers[header]}" end)
    |> Enum.join("\n")
  end

  def sign(%Actor{} = actor, headers) do
    sigstring = build_signing_string(headers, Map.keys(headers))

    signature = sigstring |> :public_key.sign(:sha256, actor.keys) |> Base.encode64()

    [
      keyId: actor.url <> "#main-key",
      algorithm: "rsa-sha256",
      headers: headers |> Map.keys() |> Enum.join(" "),
      signature: signature
    ]
    |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
    |> Enum.join(",")
  end
end
