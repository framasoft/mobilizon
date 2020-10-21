defmodule Mobilizon.Service.HTTP.WebfingerClient do
  @moduledoc """
  Tesla HTTP Basic Client
  with JSON middleware
  """

  use Tesla
  alias Mobilizon.Config

  @default_opts [
    recv_timeout: 20_000
  ]

  adapter(Tesla.Adapter.Hackney, @default_opts)

  @user_agent Config.instance_user_agent()

  plug(Tesla.Middleware.FollowRedirects)

  plug(Tesla.Middleware.Timeout, timeout: 10_000)

  plug(Tesla.Middleware.Headers, [
    {"User-Agent", @user_agent},
    {"Accept", "application/json, application/activity+json, application/jrd+json"}
  ])

  plug(Tesla.Middleware.JSON,
    decode_content_types: [
      "application/jrd+json",
      "application/json",
      "application/activity+json"
    ]
  )
end
