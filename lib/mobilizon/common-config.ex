defmodule Mobilizon.CommonConfig do
  def registrations_open?(), do: instance_config() |> get_in([:registrations_open])

  def instance_name(), do: instance_config() |> get_in([:name])

  defp instance_config(), do: Application.get_env(:mobilizon, :instance)
end
