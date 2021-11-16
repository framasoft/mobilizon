defmodule Mobilizon.Federation.ActivityPub.Fetcher do
  @moduledoc """
  Module to handle direct URL ActivityPub fetches to remote content

  If you need to first get cached data, see `Mobilizon.Federation.ActivityPub.fetch_object_from_url/2`
  """
  require Logger

  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Federation.ActivityPub.{Relay, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Converter.Actor, as: ActorConverter
  alias Mobilizon.Service.ErrorReporting.Sentry
  alias Mobilizon.Service.HTTP.ActivityPub, as: ActivityPubClient

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [maybe_date_fetch: 2, sign_fetch: 5, origin_check?: 2]

  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  @spec fetch(String.t(), Keyword.t()) ::
          {:ok, map()}
          | {:error,
             :invalid_url | :http_gone | :http_error | :http_not_found | :content_not_json}
  def fetch(url, options \\ []) do
    on_behalf_of = Keyword.get(options, :on_behalf_of, Relay.get_actor())
    date = Signature.generate_date_header()

    headers =
      [{:Accept, "application/activity+json"}]
      |> maybe_date_fetch(date)
      |> sign_fetch(on_behalf_of, url, date, options)

    client = ActivityPubClient.client(headers: headers)

    if address_valid?(url) do
      case ActivityPubClient.get(client, url) do
        {:ok, %Tesla.Env{body: data, status: code}} when code in 200..299 and is_map(data) ->
          {:ok, data}

        {:ok, %Tesla.Env{status: 410}} ->
          Logger.debug("Resource at #{url} is 410 Gone")
          {:error, :http_gone}

        {:ok, %Tesla.Env{status: 404}} ->
          Logger.debug("Resource at #{url} is 404 Gone")
          {:error, :http_not_found}

        {:ok, %Tesla.Env{body: data}} when is_binary(data) ->
          {:error, :content_not_json}

        {:ok, %Tesla.Env{} = res} ->
          Logger.debug("Resource returned bad HTTP code #{inspect(res)}")
          {:error, :http_error}

        {:error, err} ->
          {:error, err}
      end
    else
      {:error, :invalid_url}
    end
  end

  @spec fetch_and_create(String.t(), Keyword.t()) ::
          {:ok, map(), struct()} | {:error, atom()} | :error
  def fetch_and_create(url, options \\ []) do
    case fetch(url, options) do
      {:ok, data} when is_map(data) ->
        if origin_check?(url, data) do
          case Transmogrifier.handle_incoming(%{
                 "type" => "Create",
                 "to" => data["to"],
                 "cc" => data["cc"],
                 "actor" => data["actor"] || data["attributedTo"],
                 "attributedTo" => data["attributedTo"] || data["actor"],
                 "object" => data
               }) do
            {:ok, entity, structure} ->
              {:ok, entity, structure}

            {:error, error} when is_atom(error) ->
              {:error, error}

            :error ->
              {:error, :transmogrifier_error}
          end
        else
          Logger.warn("Object origin check failed")
          {:error, :object_origin_check_failed}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_and_update(String.t(), Keyword.t()) ::
          {:ok, map(), struct()} | {:error, atom()}
  def fetch_and_update(url, options \\ []) do
    case fetch(url, options) do
      {:ok, data} when is_map(data) ->
        if origin_check(url, data) do
          Transmogrifier.handle_incoming(%{
            "type" => "Update",
            "to" => data["to"],
            "cc" => data["cc"],
            "actor" => data["actor"] || data["attributedTo"],
            "attributedTo" => data["attributedTo"] || data["actor"],
            "object" => data
          })
        else
          Logger.warn("Object origin check failed")
          {:error, :object_origin_check_failed}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  @type fetch_actor_errors ::
          :json_decode_error | :actor_deleted | :http_error | :actor_not_allowed_type

  @doc """
  Fetching a remote actor's information through its AP ID
  """
  @spec fetch_and_prepare_actor_from_url(String.t()) ::
          {:ok, map()} | {:error, fetch_actor_errors}
  def fetch_and_prepare_actor_from_url(url, options \\ []) do
    Logger.debug("Fetching and preparing actor from url")
    Logger.debug(inspect(url))

    case fetch(url, options) do
      {:ok, data} ->
        case ActorConverter.as_to_model_data(data) do
          {:error, :actor_not_allowed_type} ->
            {:error, :actor_not_allowed_type}

          map when is_map(map) ->
            {:ok, map}
        end

      {:error, :http_gone} ->
        Logger.info("Response HTTP 410")
        {:error, :actor_deleted}

      {:error, :http_error} ->
        Logger.info("Non 200 HTTP Code")
        {:error, :http_error}

      {:error, error} ->
        Logger.warn("Could not fetch actor at fetch #{url}, #{inspect(error)}")
        {:error, :http_error}
    end
  end

  @spec origin_check(String.t(), map()) :: boolean()
  defp origin_check(url, data) do
    if origin_check?(url, data) do
      true
    else
      Sentry.capture_message("Object origin check failed", extra: %{url: url, data: data})
      Logger.debug("Object origin check failed between #{inspect(url)} and #{inspect(data)}")
      false
    end
  end

  @spec address_valid?(String.t()) :: boolean
  defp address_valid?(address) do
    %URI{host: host, scheme: scheme} = URI.parse(address)
    is_valid_string(host) and is_valid_string(scheme)
  end
end
