defmodule Mobilizon.Web.Upload.Filter.Resize do
  @moduledoc """
  Resize the pictures if they're bigger than maximum size.

  This filter requires `Mobilizon.Web.Upload.Filter.AnalyzeMetadata` to be performed before.
  """

  @behaviour Mobilizon.Web.Upload.Filter
  alias Mobilizon.Web.Upload

  @maximum_width 1_920
  @maximum_height 1_080

  @spec filter(Upload.t()) :: {:ok, :filtered, Upload.t()} | {:ok, :noop}
  def filter(
        %Upload{
          tempfile: file,
          content_type: "image" <> _,
          width: width,
          height: height
        } = upload
      ) do
    {new_width, new_height} = sizes = limit_sizes({width, height})

    file
    |> Mogrify.open()
    |> Mogrify.resize(string(sizes))
    |> Mogrify.save(in_place: true)

    {:ok, :filtered, %Upload{upload | width: new_width, height: new_height}}
  end

  def filter(_), do: {:ok, :noop}

  @spec limit_sizes({non_neg_integer, non_neg_integer}) :: {non_neg_integer, non_neg_integer}
  def limit_sizes({width, height}) when width > @maximum_width do
    new_height = round(@maximum_width * height / width)
    limit_sizes({@maximum_width, new_height})
  end

  def limit_sizes({width, height}) when height > @maximum_height do
    new_width = round(@maximum_height * width / height)
    limit_sizes({new_width, @maximum_height})
  end

  def limit_sizes({width, height}), do: {width, height}

  @spec string({non_neg_integer, non_neg_integer}) :: String.t()
  defp string({width, height}), do: "#{width}x#{height}"
end
