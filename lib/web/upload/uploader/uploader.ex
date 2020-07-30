# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/uploaders/uploader.ex

defmodule Mobilizon.Web.Upload.Uploader do
  @moduledoc """
  Defines the contract to put and get an uploaded file to any backend.
  """

  @doc """
  Instructs how to get the file from the backend.

  Used by `Mobilizon.Web.Plugs.UploadedMedia`.
  """
  @type get_method :: {:static_dir, directory :: String.t()} | {:url, url :: String.t()}
  @callback get_file(file :: String.t()) :: {:ok, get_method()}

  @doc """
  Put a file to the backend.

  Returns:

    * `:ok` which assumes `{:ok, upload.path}`
    * `{:ok, spec}` where spec is:
      * `{:file, filename :: String.t}` to handle reads with `get_file/1` (recommended)

      This allows to correctly proxy or redirect requests to the backend, while allowing to migrate backends without breaking any URL.
    * `{url, url :: String.t}` to bypass `get_file/2` and use the `url` directly in the activity.
    * `{:error, String.t}` error information if the file failed to be saved to the backend.
    * `:wait_callback` will wait for an http post request at `/api/pleroma/upload_callback/:upload_path` and call the uploader's `http_callback/3` method.

  """
  @type file_spec :: {:file | :url, String.t()}
  @callback put_file(Mobilizon.Web.Upload.t()) ::
              :ok | {:ok, file_spec()} | {:error, String.t()} | :wait_callback

  @callback remove_file(file_spec()) :: :ok | {:ok, file_spec()} | {:error, String.t()}

  @callback http_callback(Plug.Conn.t(), map()) ::
              {:ok, Plug.Conn.t()}
              | {:ok, Plug.Conn.t(), file_spec()}
              | {:error, Plug.Conn.t(), String.t()}
  @optional_callbacks http_callback: 2

  @spec put_file(module(), Mobilizon.Web.Upload.t()) :: {:ok, file_spec()} | {:error, String.t()}
  def put_file(uploader, upload) do
    case uploader.put_file(upload) do
      :ok -> {:ok, {:file, upload.path}}
      :wait_callback -> handle_callback(uploader, upload)
      {:ok, _} = ok -> ok
      {:error, _} = error -> error
    end
  end

  def remove_file(uploader, path) do
    uploader.remove_file(path)
  end

  defp handle_callback(uploader, upload) do
    :global.register_name({__MODULE__, upload.path}, self())

    receive do
      {__MODULE__, pid, conn, params} ->
        case uploader.http_callback(conn, params) do
          {:ok, conn, ok} ->
            send(pid, {__MODULE__, conn})
            {:ok, ok}

          {:error, conn, error} ->
            send(pid, {__MODULE__, conn})
            {:error, error}
        end
    after
      30_000 -> {:error, "Uploader callback timeout"}
    end
  end
end
