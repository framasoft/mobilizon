defmodule Mobilizon.Service.FrontEndAnalytics do
  @moduledoc """
  Behaviour for any analytics service
  """

  @callback id() :: String.t()

  @doc """
  Whether the service is enabled
  """
  @callback enabled?() :: boolean()

  @doc """
  The configuration for the service
  """
  @callback configuration() :: map()

  @spec providers :: list(module())
  def providers do
    :mobilizon
    |> Application.get_env(:analytics, [])
    |> Keyword.get(:providers, [])
  end

  @spec config :: map()
  def config do
    Enum.reduce(providers(), [], &load_config/2)
  end

  @spec load_config(module(), map()) :: map()
  defp load_config(provider, acc) do
    acc ++
      [
        %{
          id: provider.id(),
          enabled: provider.enabled?(),
          configuration: convert_config(provider.configuration())
        }
      ]
  end

  @spec convert_config(Keyword.t()) :: list(map())
  defp convert_config(config) do
    Enum.reduce(config, [], fn {key, val}, acc ->
      acc ++ [%{key: key, value: val, type: type(val)}]
    end)
  end

  defp type(val) when is_integer(val), do: :integer
  defp type(val) when is_float(val), do: :float
  defp type(val) when is_boolean(val), do: :boolean
  defp type(val) when is_binary(val), do: :string
end
