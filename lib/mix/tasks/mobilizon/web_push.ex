defmodule Mix.Tasks.Mobilizon.WebPush.Gen.Keypair do
  @moduledoc """
  Task to generate WebPush configuration

  Taken from https://github.com/danhper/elixir-web-push-encryption/blob/8fd0f71f3222b466d389f559be9800c49f9bb641/lib/mix/tasks/web_push_gen_keypair.ex
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common, only: [mix_shell?: 0]

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(_) do
    {public, private} = :crypto.generate_key(:ecdh, :prime256v1)

    IO.puts("# Put the following in your #{file_name()} config file:")
    IO.puts("")
    IO.puts("config :web_push_encryption, :vapid_details,")
    IO.puts("  subject: \"mailto:administrator@example.com\",")
    IO.puts("  public_key: \"#{ub64(public)}\",")
    IO.puts("  private_key: \"#{ub64(private)}\"")
    IO.puts("")
  end

  defp ub64(value) do
    Base.url_encode64(value, padding: false)
  end

  defp file_name do
    if mix_shell?(), do: "runtime.exs", else: "config.exs"
  end
end
