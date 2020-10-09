# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload.ex

defmodule Mobilizon.Web.Upload do
  @moduledoc """
  Manage user uploads

  Options:
    * `:type`: presets for activity type (defaults to Document) and size limits from app configuration
    * `:description`: upload alternative text
    * `:base_url`: override base url
    * `:uploader`: override uploader
    * `:filters`: override filters
    * `:size_limit`: override size limit
    * `:activity_type`: override activity type

  The `%Mobilizon.Web.Upload{}` struct: all documented fields are meant to be overwritten in filters:

    * `:id` - the upload id.
    * `:name` - the upload file name.
    * `:path` - the upload path: set at first to `id/name` but can be changed. Keep in mind that the path
      is once created permanent and changing it (especially in uploaders) is probably a bad idea!
    * `:tempfile` - path to the temporary file. Prefer in-place changes on the file rather than changing the
    path as the temporary file is also tracked by `Plug.Upload{}` and automatically deleted once the request is over.

  Related behaviors:

    * `Mobilizon.Web.Upload.Uploader`
    * `Mobilizon.Web.Upload.Filter`

  """

  alias Ecto.UUID

  alias Mobilizon.Config

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Upload.{Filter, MIME, Uploader}

  require Logger

  @type source ::
          Plug.Upload.t()
          | (data_uri_string :: String.t())
          | {:from_local, name :: String.t(), id :: String.t(), path :: String.t()}

  @type option ::
          {:type, :avatar | :banner | :background}
          | {:description, String.t()}
          | {:activity_type, String.t()}
          | {:size_limit, nil | non_neg_integer()}
          | {:uploader, module()}
          | {:filters, [module()]}

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          tempfile: String.t(),
          content_type: String.t(),
          path: String.t(),
          size: integer()
        }
  defstruct [:id, :name, :tempfile, :content_type, :path, :size]

  @spec store(source, options :: [option()]) :: {:ok, map()} | {:error, any()}
  def store(upload, opts \\ []) do
    opts = get_opts(opts)

    with {:ok, upload} <- prepare_upload(upload, opts),
         upload = %__MODULE__{upload | path: upload.path || "#{upload.id}/#{upload.name}"},
         {:ok, upload} <- Filter.filter(opts.filters, upload),
         {:ok, url_spec} <- Uploader.put_file(opts.uploader, upload) do
      {:ok,
       %{
         name: Map.get(opts, :description) || upload.name,
         url: url_from_spec(upload, opts.base_url, url_spec),
         content_type: upload.content_type,
         size: upload.size
       }}
    else
      {:error, error} ->
        Logger.error(
          "#{__MODULE__} store (using #{inspect(opts.uploader)}) failed: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  def remove(url, opts \\ []) do
    with opts <- get_opts(opts),
         %URI{path: "/media/" <> path, host: host} <- URI.parse(url),
         {:same_host, true} <- {:same_host, host == Endpoint.host()} do
      Uploader.remove_file(opts.uploader, path)
    else
      %URI{} = _uri ->
        {:error, "URL doesn't match pattern"}

      {:same_host, _} ->
        Logger.error("Media can't be deleted because its URL doesn't match current host")
    end
  end

  def char_unescaped?(char) do
    URI.char_unreserved?(char) or char == ?/
  end

  defp get_opts(opts) do
    {size_limit, activity_type} =
      case Keyword.get(opts, :type) do
        :banner ->
          {Config.get!([:instance, :banner_upload_limit]), "Image"}

        :avatar ->
          {Config.get!([:instance, :avatar_upload_limit]), "Image"}

        _ ->
          {Config.get!([:instance, :upload_limit]), nil}
      end

    %{
      activity_type: Keyword.get(opts, :activity_type, activity_type),
      size_limit: Keyword.get(opts, :size_limit, size_limit),
      uploader: Keyword.get(opts, :uploader, Config.get([__MODULE__, :uploader])),
      filters: Keyword.get(opts, :filters, Config.get([__MODULE__, :filters])),
      description: Keyword.get(opts, :description),
      allow_list_mime_types:
        Keyword.get(
          opts,
          :allow_list_mime_types,
          Config.get([__MODULE__, :allow_list_mime_types])
        ),
      base_url:
        Keyword.get(
          opts,
          :base_url,
          Config.get([__MODULE__, :base_url], Endpoint.url())
        )
    }
  end

  defp prepare_upload(%Plug.Upload{} = file, opts) do
    with {:ok, size} <- check_file_size(file.path, opts.size_limit),
         {:ok, content_type, name} <- MIME.file_mime_type(file.path, file.filename),
         :ok <- check_allowed_mime_type(content_type, opts.allow_list_mime_types) do
      {:ok,
       %__MODULE__{
         id: UUID.generate(),
         name: name,
         tempfile: file.path,
         content_type: content_type,
         size: size
       }}
    end
  end

  defp prepare_upload(%{body: body, name: name} = _file, opts) do
    with :ok <- check_binary_size(body, opts.size_limit),
         tmp_path <- tempfile_for_image(body),
         {:ok, content_type, name} <- MIME.file_mime_type(tmp_path, name),
         :ok <- check_allowed_mime_type(content_type, opts.allow_list_mime_types) do
      {:ok,
       %__MODULE__{
         id: UUID.generate(),
         name: name,
         tempfile: tmp_path,
         content_type: content_type,
         size: byte_size(body)
       }}
    end
  end

  defp check_file_size(path, size_limit) when is_integer(size_limit) and size_limit > 0 do
    with {:ok, %{size: size}} <- File.stat(path),
         true <- size <= size_limit do
      {:ok, size}
    else
      false -> {:error, :file_too_large}
      error -> error
    end
  end

  defp check_file_size(_, _), do: :ok

  defp check_binary_size(binary, size_limit)
       when is_integer(size_limit) and size_limit > 0 and byte_size(binary) >= size_limit do
    {:error, :file_too_large}
  end

  defp check_binary_size(_, _), do: :ok

  # Creates a tempfile using the Plug.Upload Genserver which cleans them up
  # automatically.
  defp tempfile_for_image(data) do
    {:ok, tmp_path} = Plug.Upload.random_file("temp_files")
    {:ok, tmp_file} = File.open(tmp_path, [:write, :raw, :binary])
    IO.binwrite(tmp_file, data)

    tmp_path
  end

  defp url_from_spec(%__MODULE__{name: name}, base_url, {:file, path}) do
    path =
      URI.encode(path, &char_unescaped?/1) <>
        if Config.get([__MODULE__, :link_name], false) do
          "?name=#{URI.encode(name, &char_unescaped?/1)}"
        else
          ""
        end

    [base_url, "media", path]
    |> Path.join()
  end

  defp url_from_spec(_upload, _base_url, {:url, url}), do: url

  @spec check_allowed_mime_type(String.t(), List.t()) :: :ok | {:error, :atom}
  defp check_allowed_mime_type(content_type, allow_list_mime_types) do
    if Enum.any?(allow_list_mime_types, &(&1 == content_type)),
      do: :ok,
      else: {:error, :mime_type_not_allowed}
  end
end
