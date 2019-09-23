defmodule Mobilizon.Config do
  @moduledoc """
  Configuration wrapper.
  """

  @spec instance_config :: keyword
  def instance_config, do: Application.get_env(:mobilizon, :instance)

  @spec instance_name :: String.t()
  def instance_name, do: instance_config()[:name]

  @spec instance_description :: String.t()
  def instance_description, do: instance_config()[:description]

  @spec instance_version :: String.t()
  def instance_version, do: instance_config()[:version]

  @spec instance_hostname :: String.t()
  def instance_hostname, do: instance_config()[:hostname]

  @spec instance_registrations_open? :: boolean
  def instance_registrations_open?, do: to_boolean(instance_config()[:registrations_open])

  @spec instance_repository :: String.t()
  def instance_repository, do: instance_config()[:repository]

  @spec instance_email_from :: String.t()
  def instance_email_from, do: instance_config()[:email_from]

  @spec instance_email_reply_to :: String.t()
  def instance_email_reply_to, do: instance_config()[:email_reply_to]

  @spec get(module | atom) :: any
  def get(key), do: get(key, nil)

  @spec get([module | atom]) :: any
  def get([key], default), do: get(key, default)

  def get([parent_key | keys], default) do
    case get_in(Application.get_env(:mobilizon, parent_key), keys) do
      nil -> default
      any -> any
    end
  end

  @spec get(module | atom, any) :: any
  def get(key, default), do: Application.get_env(:mobilizon, key, default)

  @spec get!(module | atom) :: any
  def get!(key) do
    value = get(key, nil)

    if value == nil do
      raise("Missing configuration value: #{inspect(key)}")
    else
      value
    end
  end

  @spec put([module | atom], any) :: any
  def put([key], value), do: put(key, value)

  def put([parent_key | keys], value) do
    parent = put_in(Application.get_env(:mobilizon, parent_key), keys, value)

    Application.put_env(:mobilizon, parent_key, parent)
  end

  @spec put(module | atom, any) :: any
  def put(key, value), do: Application.put_env(:mobilizon, key, value)

  @spec to_boolean(boolean | String.t()) :: boolean
  defp to_boolean(boolean), do: "true" == String.downcase("#{boolean}")
end
