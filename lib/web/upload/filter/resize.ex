defmodule Mobilizon.Web.Upload.Filter.Resize do
  @moduledoc """
  Resize the pictures if they're bigger than maximum size.

  This filter requires `Mobilizon.Web.Upload.Filter.AnalyzeMetadata` to be performed before.
  """

  @behaviour Mobilizon.Web.Upload.Filter

  @maximum_width 1_920
  @maximum_height 1_080

  def filter(%Mobilizon.Web.Upload{
        tempfile: file,
        content_type: "image" <> _,
        width: width,
        height: height
      }) do
    file
    |> Mogrify.open()
    |> Mogrify.resize(string(limit_sizes({width, height})))
    |> Mogrify.save(in_place: true)

    {:ok, :filtered}
  end

  def filter(_), do: {:ok, :noop}

  def limit_sizes({width, height}) when width > @maximum_width do
    new_height = round(@maximum_width * height / width)
    limit_sizes({@maximum_width, new_height})
  end

  def limit_sizes({width, height}) when height > @maximum_height do
    new_width = round(@maximum_height * width / height)
    limit_sizes({new_width, @maximum_height})
  end

  def limit_sizes({width, height}), do: {width, height}

  defp string({width, height}), do: "#{width}x#{height}"
end
