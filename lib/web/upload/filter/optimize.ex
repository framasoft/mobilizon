defmodule Mobilizon.Web.Upload.Filter.Optimize do
  @moduledoc """
  Handle picture optimizations
  """

  @behaviour Mobilizon.Web.Upload.Filter

  alias Mobilizon.Config

  @default_optimizers [
    JpegOptim,
    PngQuant,
    Optipng,
    Svgo,
    Gifsicle,
    Cwebp
  ]

  def filter(%Mobilizon.Web.Upload{tempfile: file, content_type: "image" <> _}) do
    optimizers = Config.get([__MODULE__, :optimizers], @default_optimizers)

    case ExOptimizer.optimize(file, deps: optimizers) do
      {:ok, _res} ->
        :ok

      {:error, err} ->
        require Logger

        Logger.warn(
          "Unable to optimize file #{file}. The return from the process was #{inspect(err)}"
        )

        :ok

      err ->
        err
    end
  end

  def filter(_), do: :ok
end
