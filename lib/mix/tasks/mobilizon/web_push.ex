defmodule Mix.Tasks.Mobilizon.WebPush.Gen.Keypair do
  @moduledoc """
  Task to generate WebPush configuration

  Taken from https://github.com/danhper/elixir-web-push-encryption/blob/8fd0f71f3222b466d389f559be9800c49f9bb641/lib/mix/tasks/web_push_gen_keypair.ex
  """
  use Mix.Task

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(_) do
    {public, private} = :crypto.generate_key(:ecdh, :prime256v1)

    IO.puts("Public and private VAPID keys have been generated.")
    IO.puts("")

    if is_nil(System.get_env("MOBILIZON_DOCKER")) do
      IO.puts("# Put the following in your runtime.exs config file:")
      IO.puts("")
      IO.puts("config :web_push_encryption, :vapid_details,")
      IO.puts("  subject: \"mailto:administrator@example.com\",")
      IO.puts("  public_key: \"#{ub64(public)}\",")
      IO.puts("  private_key: \"#{ub64(private)}\"")
      IO.puts("")
    else
      IO.puts("# Set the following environment variables in your .env file:")
      IO.puts("")
      IO.puts("MOBILIZON_WEB_PUSH_ENCRYPTION_SUBJECT=\"mailto:administrator@example.com\"")
      IO.puts("MOBILIZON_WEB_PUSH_ENCRYPTION_PUBLIC_KEY=\"#{ub64(public)}\"")
      IO.puts("MOBILIZON_WEB_PUSH_ENCRYPTION_PRIVATE_KEY=\"#{ub64(private)}\"")
      IO.puts("")
    end
  end

  defp ub64(value) do
    Base.url_encode64(value, padding: false)
  end
end
