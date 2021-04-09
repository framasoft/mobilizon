defmodule Mobilizon.Service.HTTP.ActivityPub do
  @moduledoc """
  Tesla HTTP Client that is preconfigured to get and post ActivityPub content
  """

  alias Mobilizon.Config

  @default_opts [
    recv_timeout: 20_000
  ]

  def client(options \\ []) do
    headers = Keyword.get(options, :headers, [])
    adapter = Application.get_env(:tesla, __MODULE__, [])[:adapter] || Tesla.Adapter.Hackney
    opts = Keyword.merge(@default_opts, Keyword.get(options, :opts, []))

    middleware = [
      {Tesla.Middleware.Headers,
       [{"User-Agent", Config.instance_user_agent()}, {"Accept", "application/activity+json"}] ++
         headers},
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Timeout, timeout: 10_000},
      {Tesla.Middleware.JSON,
       decode_content_types: ["application/activity+json", "application/ld+json"]}
    ]

    Tesla.client(middleware, {adapter, opts})
  end

  def get(client, url) do
    Tesla.get(client, url)
  end

  def post(client, url, data) do
    Tesla.post(client, url, data)
  end
end
