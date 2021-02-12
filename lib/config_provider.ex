defmodule Mobilizon.ConfigProvider do
  @moduledoc """
  Module to provide configuration from a custom file
  """
  @behaviour Config.Provider

  def init(path) when is_binary(path), do: path

  def load(config, path) do
    config_path = System.get_env("MOBILIZON_CONFIG_PATH") || path

    cond do
      File.exists?(config_path) ->
        runtime_config = Config.Reader.read!(config_path)

        Config.Reader.merge(config, runtime_config)

      is_nil(System.get_env("MOBILIZON_DOCKER")) ->
        warning = [
          IO.ANSI.red(),
          IO.ANSI.bright(),
          "!!! #{config_path} not found! Please ensure it exists and that MOBILIZON_CONFIG_PATH is unset or points to an existing file",
          IO.ANSI.reset()
        ]

        IO.puts(warning)
        config

      true ->
        IO.puts("No runtime config file found, but using environment variables for Docker")
        config
    end
  end
end
