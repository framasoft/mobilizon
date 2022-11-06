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
  @callback configuration() :: keyword()

  @doc """
  The CSP configuration to add for the service to work
  """
  @callback csp() :: keyword()

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

  @spec csp :: keyword()
  def csp do
    providers()
    |> Enum.map(& &1.csp())
    |> Enum.reduce([], &merge_csp_config/2)
  end

  @spec load_config(module(), list(map())) :: list(map())
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

  defp merge_csp_config(config, global_config) do
    Keyword.merge(global_config, config, fn _key, global, config ->
      global ++ config
    end)
  end
end
