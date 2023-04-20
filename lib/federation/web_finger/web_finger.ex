# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/web_finger/web_finger.ex

defmodule Mobilizon.Federation.WebFinger do
  @moduledoc """
  Performs the WebFinger requests and responses (JSON only).
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.WebFinger.XmlBuilder
  alias Mobilizon.Service.HTTP.{HostMetaClient, WebfingerClient}
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes
  require Jason
  require Logger
  import SweetXml

  @env Application.compile_env(:mobilizon, :env)

  @doc """
  Returns the Web Host Metadata (for `/.well-known/host-meta`) representation for the instance, following RFC6414.
  """
  @spec host_meta :: String.t()
  def host_meta do
    base_url = Endpoint.url()
    %URI{host: host} = URI.parse(base_url)

    XmlBuilder.to_doc({
      :XRD,
      %{
        xmlns: "http://docs.oasis-open.org/ns/xri/xrd-1.0",
        "xmlns:hm": "http://host-meta.net/ns/1.0"
      },
      [
        {
          :"hm:Host",
          host
        },
        {
          :Link,
          %{
            rel: "lrdd",
            type: "application/jrd+json",
            template: "#{base_url}/.well-known/webfinger?resource={uri}"
          }
        }
      ]
    })
  end

  @doc """
  Returns the Webfinger representation for the instance, following RFC7033.
  """
  @spec webfinger(String.t(), String.t()) :: {:ok, map} | {:error, :actor_not_found}
  def webfinger(resource, "JSON") do
    host = Endpoint.host()
    regex = ~r/(acct:)?(?<name>\w+)@#{host}/

    with %{"name" => name} <- Regex.named_captures(regex, resource),
         %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      {:ok, represent_actor(actor, "JSON")}
    else
      _e ->
        case ActivityPubActor.get_or_fetch_actor_by_url(resource) do
          {:ok, %Actor{} = actor} when not is_nil(actor) ->
            {:ok, represent_actor(actor, "JSON")}

          _e ->
            {:error, :actor_not_found}
        end
    end
  end

  @doc """
  Return an `Mobilizon.Actors.Actor` Webfinger representation (as JSON)
  """
  @spec represent_actor(Actor.t(), String.t()) :: map()
  def represent_actor(%Actor{} = actor, "JSON") do
    links =
      [
        %{"rel" => "self", "type" => "application/activity+json", "href" => actor.url},
        %{
          "rel" => "http://ostatus.org/schema/1.0/subscribe",
          "template" => "#{Routes.page_url(Endpoint, :interact, uri: nil)}{uri}"
        }
      ]
      |> maybe_add_avatar(actor)
      |> maybe_add_profile_page(actor)

    %{
      "subject" => "acct:#{actor.preferred_username}@#{Endpoint.host()}",
      "aliases" => [actor.url],
      "links" => links
    }
  end

  @spec maybe_add_avatar(list(map()), Actor.t()) :: list(map())
  defp maybe_add_avatar(data, %Actor{avatar: avatar}) when not is_nil(avatar) do
    data ++
      [
        %{
          "rel" => "http://webfinger.net/rel/avatar",
          "type" => avatar.content_type,
          "href" => avatar.url
        }
      ]
  end

  defp maybe_add_avatar(data, _actor), do: data

  @spec maybe_add_profile_page(list(map()), Actor.t()) :: list(map())
  defp maybe_add_profile_page(data, %Actor{type: :Group, url: url}) do
    data ++
      [
        %{
          "rel" => "http://webfinger.net/rel/profile-page/",
          "type" => "text/html",
          "href" => url
        }
      ]
  end

  defp maybe_add_profile_page(data, _actor), do: data

  @type finger_errors ::
          :host_not_found
          | :address_invalid
          | :http_error
          | :webfinger_information_not_json
          | :webfinger_information_not_valid
          | :no_url_in_webfinger_data

  @doc """
  Finger an actor to retreive it's ActivityPub ID/URL

  Fetches the Extensible Resource Descriptor endpoint `/.well-known/host-meta` to find the Webfinger endpoint (usually `/.well-known/webfinger?resource=`) and then performs a Webfinger query to get the ActivityPub ID associated to an actor.
  """
  @spec finger(String.t()) ::
          {:ok, String.t()}
          | {:error, finger_errors}
  def finger(actor) do
    actor = String.trim_leading(actor, "@")

    case validate_endpoint(actor) do
      {:ok, address} ->
        case fetch_webfinger_data(address) do
          {:ok, %{"url" => url}} ->
            {:ok, url}

          {:ok, _} ->
            Logger.debug("No URL found for actor from webfinger data")
            {:error, :no_url_in_webfinger_data}

          {:error, err} ->
            Logger.debug("Couldn't process webfinger data for #{actor}")
            {:error, err}
        end

      {:error, err} ->
        Logger.debug("Couldn't find webfinger endpoint for #{actor}")
        {:error, err}
    end
  end

  @spec fetch_webfinger_data(String.t()) ::
          {:ok, map()}
          | {:error,
             :webfinger_information_not_json | :webfinger_information_not_valid | :http_error}
  defp fetch_webfinger_data(address) do
    Logger.debug("Calling WebfingerClient with #{inspect(address)}")

    case WebfingerClient.get(address) do
      {:ok, %{body: body, status: code}} when code in 200..299 ->
        webfinger_from_json(body)

      err ->
        Logger.debug("Failed to fetch webfinger data #{inspect(err)}")
        {:error, :http_error}
    end
  end

  @spec validate_endpoint(String.t()) ::
          {:ok, String.t()} | {:error, :address_invalid | :host_not_found}
  defp validate_endpoint(actor) do
    case apply_webfinger_endpoint(actor) do
      address when is_binary(address) ->
        if address_invalid(address) do
          Logger.info("Webfinger endpoint seems to be an invalid URL #{inspect(address)}")
          {:error, :address_invalid}
        else
          {:ok, address}
        end

      _ ->
        Logger.info("Host not found in actor address #{inspect(actor)}")
        {:error, :host_not_found}
    end
  end

  # Fetches the Extensible Resource Descriptor endpoint `/.well-known/host-meta`
  # to find the Webfinger endpoint (usually `/.well-known/webfinger?resource=`)
  @spec find_webfinger_endpoint(String.t()) ::
          {:ok, String.t()} | {:error, :link_not_found} | {:error, any()}
  defp find_webfinger_endpoint(domain) when is_binary(domain) do
    Logger.debug("Calling HostMetaClient for #{domain}")
    prefix = if @env !== :dev, do: "https", else: "http"

    with {:ok, %Tesla.Env{status: 200, body: body}} <-
           HostMetaClient.get("#{prefix}://#{domain}/.well-known/host-meta"),
         link_template when is_binary(link_template) <- find_link_from_template(body) do
      {:ok, link_template}
    else
      {:ok, %Tesla.Env{status: 404}} -> {:error, :entity_not_found}
      {:ok, %Tesla.Env{}} -> {:error, :http_error}
      {:error, :link_not_found} -> {:error, :link_not_found}
      {:error, error} -> {:error, error}
    end
  end

  @spec apply_webfinger_endpoint(String.t()) :: String.t() | {:error, :host_not_found}
  defp apply_webfinger_endpoint(actor) do
    with {:ok, domain} <- domain_from_federated_actor(actor) do
      case find_webfinger_endpoint(domain) do
        {:ok, link_template} ->
          Logger.debug("Using webfinger location provided by host-meta endpoint")
          String.replace(link_template, "{uri}", "acct:#{actor}")

        _ ->
          Logger.debug("Using default webfinger location")

          prefix = if @env !== :dev, do: "https", else: "http"

          "#{prefix}://#{domain}/.well-known/webfinger?resource=acct:#{actor}"
      end
    end
  end

  @spec domain_from_federated_actor(String.t()) :: {:ok, String.t()} | {:error, :host_not_found}
  defp domain_from_federated_actor(actor) do
    case String.split(actor, "@") do
      [_name, domain] ->
        {:ok, domain}

      _e ->
        host = URI.parse(actor).host
        if is_nil(host), do: {:error, :host_not_found}, else: {:ok, host}
    end
  end

  @spec webfinger_from_json(map() | String.t()) ::
          {:ok, map()}
          | {:error, :webfinger_information_not_json | :webfinger_information_not_valid}
  defp webfinger_from_json(doc) when is_map(doc) do
    links = Map.get(doc, "links")
    subject = Map.get(doc, "subject")

    if !is_nil(links) && !is_nil(subject) do
      data = Enum.reduce(links, %{"subject" => subject}, &handle_link/2)

      {:ok, data}
    else
      {:error, :webfinger_information_not_valid}
    end
  end

  defp webfinger_from_json(_doc), do: {:error, :webfinger_information_not_json}

  @spec handle_link(map(), map()) :: map()
  defp handle_link(link, data) do
    case {link["type"], link["rel"]} do
      {"application/activity+json", "self"} ->
        Map.put(data, "url", link["href"])

      {nil, _rel} ->
        Logger.debug("No type declared for the following link #{inspect(link)}")
        data

      _ ->
        Logger.debug(fn ->
          "Unhandled type to finger: #{inspect(link)}"
        end)

        data
    end
  end

  @spec find_link_from_template(String.t()) :: String.t() | {:error, :link_not_found}
  defp find_link_from_template(doc) do
    with res when res in [nil, ""] <-
           xpath(doc, ~x"//Link[@rel=\"lrdd\"][@type=\"application/json\"]/@template"s),
         res when res in [nil, ""] <- xpath(doc, ~x"//Link[@rel=\"lrdd\"]/@template"s),
         do: {:error, :link_not_found}
  catch
    :exit, _e ->
      {:error, :link_not_found}
  end

  @spec address_invalid(String.t()) :: false | {:error, :invalid_address}
  defp address_invalid(address) do
    with %URI{host: host, scheme: scheme} <- URI.parse(address),
         true <- is_nil(host) or is_nil(scheme) do
      {:error, :invalid_address}
    end
  end
end
