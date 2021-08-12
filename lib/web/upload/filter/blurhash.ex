defmodule Mobilizon.Web.Upload.Filter.BlurHash do
  @moduledoc """
  Computes blurhash from the upload
  """
  require Logger
  alias Mobilizon.Web.Upload

  @behaviour Mobilizon.Web.Upload.Filter

  @spec filter(Upload.t()) ::
          {:ok, :filtered, Upload.t()} | {:ok, :noop} | {:error, String.t()}
  def filter(%Upload{tempfile: file, content_type: "image" <> _} = upload) do
    {:ok, :filtered, %Upload{upload | blurhash: generate_blurhash(file)}}
  rescue
    e in ErlangError ->
      Logger.warn("#{__MODULE__}: #{inspect(e)}")
      {:ok, :noop}
  end

  def filter(_), do: {:ok, :noop}

  defp generate_blurhash(file) do
    case :eblurhash.magick(to_charlist(file)) do
      {:ok, blurhash} ->
        to_string(blurhash)

      _ ->
        nil
    end
  end
end
