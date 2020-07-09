defmodule Mobilizon.Service.HTTP.BaseClient do
  @moduledoc """
  Tesla HTTP Basic Client
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

  plug(Tesla.Middleware.Headers, [{"User-Agent", @user_agent}])

  def get(url) do
    get(url)
  end

  def post(url, data) do
    post(url, data)
  end
end
