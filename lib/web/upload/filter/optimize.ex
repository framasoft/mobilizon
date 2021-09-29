defmodule Mobilizon.Web.Upload.Filter.Optimize do
  @moduledoc """
  Handle media optimizations
  """

  @behaviour Mobilizon.Web.Upload.Filter

  alias Mobilizon.Config
  alias Mobilizon.Web.Upload
  require Logger

  @default_optimizers [
    JpegOptim,
    PngQuant,
    Optipng,
    Svgo,
    Gifsicle,
    Cwebp
  ]

  @spec filter(Upload.t()) :: {:ok, :filtered | :noop} | {:error, :file_not_found}
  def filter(%Upload{tempfile: file, content_type: "image" <> _}) do
    optimizers = Config.get([__MODULE__, :optimizers], @default_optimizers)

    case ExOptimizer.optimize(file, deps: optimizers) do
      {:ok, _res} ->
        {:ok, :filtered}

      {:error, :file_not_found} ->
        Logger.warn("Unable to optimize file #{file}. File was not found")
        {:error, :file_not_found}

      {:error, err} ->
        Logger.warn(
          "Unable to optimize file #{file}. The return from the process was #{inspect(err)}"
        )

        {:ok, :noop}
    end
  end

  def filter(_), do: {:ok, :noop}
end
