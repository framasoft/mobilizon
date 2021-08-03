defmodule Mobilizon.Service.ErrorReporting do
  @moduledoc """
  Mpdule to load and configure error reporting adapters
  """

  @callback enabled? :: boolean()

  @callback configure :: any()

  @callback attach :: any()

  @callback handle_event(list(atom()), map(), map(), any()) :: any()

  @spec adapter :: module() | nil
  def adapter do
    adapter = Mobilizon.Config.get([__MODULE__, :adapter])
    if adapter && adapter.enabled?(), do: adapter, else: nil
  end

  def attach do
    adapter = adapter()

    if adapter do
      adapter.attach()
    end
  end

  @spec handle_event(list(atom()), map(), map(), any()) :: any()
  def handle_event(event_name, event_measurements, event_metadata, handler_config) do
    adapter = adapter()

    if adapter do
      adapter.handle_event(event_name, event_measurements, event_metadata, handler_config)
    end
  end

  @spec configure :: any()
  def configure do
    adapter = adapter()

    if adapter do
      adapter.configure()
    end
  end
end
