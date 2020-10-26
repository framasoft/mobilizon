# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/uploaders/local.ex

defmodule Mobilizon.Web.Upload.Uploader.Local do
  @moduledoc """
  Local uploader for files
  """

  @behaviour Mobilizon.Web.Upload.Uploader

  alias Mobilizon.Config
  alias Mobilizon.Web.Upload

  @impl true
  def get_file(_) do
    {:ok, {:static_dir, upload_path()}}
  end

  @impl true
  def put_file(%Upload{path: path, tempfile: tempfile}) do
    {path, file} = local_path(path)
    result_file = Path.join(path, file)

    with {:result_exists, false} <- {:result_exists, File.exists?(result_file)},
         {:temp_file_exists, true} <- {:temp_file_exists, File.exists?(tempfile)} do
      File.cp!(tempfile, result_file)
    else
      {:result_exists, _} ->
        # If the resulting file already exists, it's because of the Dedupe filter
        :ok

      {:temp_file_exists, _} ->
        {:error, "Temporary file no longer exists"}
    end
  end

  @impl true
  def remove_file(path) do
    with {path, file} <- local_path(path),
         full_path <- Path.join(path, file),
         true <- File.exists?(full_path),
         :ok <- File.rm(full_path),
         :ok <- remove_folder(path) do
      {:ok, path}
    else
      false -> {:error, "File #{path} doesn't exist"}
    end
  end

  defp remove_folder(path) do
    with {:subfolder, true} <- {:subfolder, path != upload_path()},
         {:empty_folder, {:ok, [] = _files}} <- {:empty_folder, File.ls(path)} do
      File.rmdir(path)
    else
      {:subfolder, _} -> :ok
      {:empty_folder, _} -> {:error, "Error: Folder is not empty"}
    end
  end

  defp local_path(path) do
    case Enum.reverse(String.split(path, "/", trim: true)) do
      [file] ->
        {upload_path(), file}

      [file | folders] ->
        path = Path.join([upload_path()] ++ Enum.reverse(folders))
        File.mkdir_p!(path)
        {path, file}
    end
  end

  def upload_path do
    Config.get!([__MODULE__, :uploads])
  end
end
