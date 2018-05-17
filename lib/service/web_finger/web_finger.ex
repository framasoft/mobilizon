defmodule Eventos.Service.WebFinger do

  alias Eventos.Accounts
  alias Eventos.Service.XmlBuilder
  alias Eventos.Repo
  require Jason
  require Logger

  def host_meta do
    base_url = EventosWeb.Endpoint.url()

    {
      :XRD,
      %{xmlns: "http://docs.oasis-open.org/ns/xri/xrd-1.0"},
      {
        :Link,
        %{
          rel: "lrdd",
          type: "application/xrd+xml",
          template: "#{base_url}/.well-known/webfinger?resource={uri}"
        }
      }
    }
    |> XmlBuilder.to_doc()
  end

  def webfinger(resource, "JSON") do
    host = EventosWeb.Endpoint.host()
    regex = ~r/(acct:)?(?<username>\w+)@#{host}/

    with %{"username" => username} <- Regex.named_captures(regex, resource) do
      user = Accounts.get_account_by_username(username)
      {:ok, represent_user(user, "JSON")}
    else
      _e ->
        with user when not is_nil(user) <- Accounts.get_account_by_url(resource) do
          {:ok, represent_user(user, "JSON")}
        else
          _e ->
            {:error, "Couldn't find user"}
        end
    end
  end

  def represent_user(user, "JSON") do
    %{
      "subject" => "acct:#{user.username}@#{EventosWeb.Endpoint.host() <> ":4001"}",
      "aliases" => [user.url],
      "links" => [
        %{"rel" => "self", "type" => "application/activity+json", "href" => user.url},
      ]
    }
  end

  defp webfinger_from_json(doc) do
    data =
      Enum.reduce(doc["links"], %{"subject" => doc["subject"]}, fn link, data ->
        case {link["type"], link["rel"]} do
          {"application/activity+json", "self"} ->
            Map.put(data, "url", link["href"])
          _ ->
            Logger.debug("Unhandled type: #{inspect(link["type"])}")
            data
        end
      end)

    {:ok, data}
  end

  def finger(account) do
    account = String.trim_leading(account, "@")

    domain =
      with [_name, domain] <- String.split(account, "@") do
        domain
      else
        _e ->
          URI.parse(account).host
      end

      address = "http://#{domain}/.well-known/webfinger?resource=acct:#{account}"

    with response <- HTTPoison.get(address, [Accept: "application/json"],follow_redirect: true),
         {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 <- response do
          {:ok, doc} = Jason.decode(body)
          webfinger_from_json(doc)
    else
      e ->
        Logger.debug(fn -> "Couldn't finger #{account}" end)
        Logger.debug(fn -> inspect(e) end)
        {:error, e}
    end
  end
end
