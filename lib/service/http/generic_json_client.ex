defmodule Mobilizon.Service.HTTP.GenericJSONClient do
  @moduledoc """
  Tesla HTTP Client that is preconfigured to get JSON content
  """

  alias Mobilizon.Config
  import Mobilizon.Service.HTTP.Utils, only: [get_tls_config: 0]

  @default_opts [
    recv_timeout: 20_000
  ]

  @spec client(Keyword.t()) :: Tesla.Client.t()
  def client(options \\ []) do
    headers = Keyword.get(options, :headers, [])
    adapter = Application.get_env(:tesla, __MODULE__, [])[:adapter] || Tesla.Adapter.Hackney

    opts =
      @default_opts
      |> Keyword.merge(ssl_options: get_tls_config())
      |> Keyword.merge(Keyword.get(options, :opts, []))

    middleware = [
      {Tesla.Middleware.Headers,
       [{"User-Agent", Config.instance_user_agent()}] ++
         headers},
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Timeout, timeout: 10_000},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware, {adapter, opts})
  end

  @spec get(Tesla.Client.t(), String.t()) :: Tesla.Env.result()
  def get(client, url) do
    Tesla.get(client, url)
  end

  @spec post(Tesla.Client.t(), String.t(), map() | String.t()) :: Tesla.Env.result()
  def post(client, url, data) do
    Tesla.post(client, url, data)
  end
end
