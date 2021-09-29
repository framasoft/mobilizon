defmodule Mobilizon.Service.ErrorReporting.Sentry do
  @moduledoc """
  Sentry adapter for error reporting
  """

  alias Mobilizon.Service.ErrorReporting
  @behaviour ErrorReporting

  @impl ErrorReporting
  def enabled? do
    !is_nil(Application.get_env(:sentry, :dsn))
  end

  @impl ErrorReporting
  def configure do
    Logger.add_backend(Sentry.LoggerBackend)
  end

  def capture_message(message, opts \\ []) when is_binary(message) do
    if enabled?() do
      Sentry.capture_message(message, opts)
    end
  end

  def capture_exception(exception, opts \\ []) do
    if enabled?() do
      Sentry.capture_exception(exception, opts)
    end
  end

  @impl ErrorReporting
  @spec attach :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.attach(
      "oban-errors",
      [:oban, :job, :exception],
      &handle_event/4,
      []
    )
  end

  @impl ErrorReporting
  def handle_event([:oban, :job, :exception], measure, %{job: job} = meta, _) do
    extra =
      job
      |> Map.take([:id, :args, :meta, :queue, :worker])
      |> Map.merge(measure)

    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: extra)
  end

  @impl ErrorReporting
  def handle_event([:oban, :circuit, :trip], _measure, meta, _) do
    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: meta)
  end

  def handle_event(_, _, _, _), do: :ok
end
