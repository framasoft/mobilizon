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

  defp instance_config(), do: Application.get_env(:mobilizon, :instance)

  defp to_bool(v), do: v == true or v == "true" or v == "True"
end
