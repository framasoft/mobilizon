defmodule Mobilizon.CommonConfig do
  @moduledoc """
  Instance configuration wrapper
  """

  def registrations_open?() do
    instance_config()
    |> get_in([:registrations_open])
    |> to_bool
  end

  def instance_name() do
    instance_config()
    |> get_in([:name])
  end

  def instance_description() do
    instance_config()
    |> get_in([:description])
  end

  def instance_hostname() do
    instance_config()
    |> get_in([:hostname])
  end

  def instance_config(), do: Application.get_env(:mobilizon, :instance)

  defp to_bool(v), do: v == true or v == "true" or v == "True"

  def get(key), do: get(key, nil)

  def get([key], default), do: get(key, default)

  def get([parent_key | keys], default) do
    case :mobilizon
         |> Application.get_env(parent_key)
         |> get_in(keys) do
      nil -> default
      any -> any
    end
  end

  def get(key, default) do
    Application.get_env(:mobilizon, key, default)
  end

  def get!(key) do
    value = get(key, nil)

    if value == nil do
      raise("Missing configuration value: #{inspect(key)}")
    else
      value
    end
  end

  def put([key], value), do: put(key, value)

  def put([parent_key | keys], value) do
    parent =
      Application.get_env(:mobilizon, parent_key)
      |> put_in(keys, value)

    Application.put_env(:mobilizon, parent_key, parent)
  end

  def put(key, value) do
    Application.put_env(:mobilizon, key, value)
  end
end
