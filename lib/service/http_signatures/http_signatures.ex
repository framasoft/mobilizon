# https://tools.ietf.org/html/draft-cavage-http-signatures-08
defmodule Eventos.Service.HTTPSignatures do
  alias Eventos.Accounts.Account
  alias Eventos.Service.ActivityPub
  require Logger

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
    Logger.debug("Signature: #{signature["signature"]}")
    Logger.debug("Sigstring: #{sigstring}")
    {:ok, sig} = Base.decode64(signature["signature"])
    Logger.debug(inspect sig)
    Logger.debug(inspect public_key)
    case ExPublicKey.verify(sigstring, sig, public_key) do
      {:ok, sig_valid} ->
        sig_valid
      {:error, err} ->
        Logger.error(err)
        false
    end
  end

  def validate_conn(conn) do
    # TODO: How to get the right key and see if it is actually valid for that request.
    # For now, fetch the key for the actor.
    with actor_id <- conn.params["actor"],
         {:ok, public_key} <- Account.get_public_key_for_url(actor_id) do
      case HTTPSign.verify(conn, public_key) do
        {:ok, conn} ->
          true
        _ ->
        Logger.debug("Could not validate, re-fetching user and trying one more time")
        # Fetch user anew and try one more time
        with actor_id <- conn.params["actor"],
             {:ok, _user} <- ActivityPub.make_account_from_url(actor_id),
             {:ok, public_key} <- Account.get_public_key_for_url(actor_id) do
          case HTTPSign.verify(conn, public_key) do
            {:ok, conn} ->
              true
            {:error, :forbidden} ->
              false
          end
        end
      end
    else
      e ->
        Logger.debug("Could not public key!")
        Logger.debug(inspect e)
        false
    end
  end

#  def validate_conn(conn, public_key) do
#    headers = Enum.into(conn.req_headers, %{})
#    signature = split_signature(headers["signature"])
#    validate(headers, signature, public_key)
#  end

  def build_signing_string(headers, used_headers) do
    used_headers
    |> Enum.map(fn header -> "#{header}: #{headers[header]}" end)
    |> Enum.join("\n")
  end

  def sign(account, headers) do
    sigstring = build_signing_string(headers, Map.keys(headers))

    {:ok, private_key} = Account.get_private_key_for_account(account)

    Logger.debug("private_key")
    Logger.debug(inspect private_key)
    Logger.debug("sigstring")
    Logger.debug(inspect sigstring)
    {:ok, signature} = HTTPSign.Crypto.sign(:rsa, sigstring, private_key)
    Logger.debug(inspect signature)

    signature = Base.encode64(signature)

    sign = [
      keyId: account.url <> "#main-key",
      algorithm: "rsa-sha256",
      headers: Map.keys(headers) |> Enum.join(" "),
      signature: signature
    ]
    |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
    |> Enum.join(",")

    Logger.debug("sign")
    Logger.debug(inspect sign)
    {:ok, public_key} = Account.get_public_key_for_account(account)
    Logger.debug("inspect split signature inside sign")
    Logger.debug(inspect split_signature(sign))
    Logger.debug(inspect validate(headers, split_signature(sign), public_key))
    sign
  end
end
