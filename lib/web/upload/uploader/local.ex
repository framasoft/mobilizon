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

  @impl true
  def get_file(_) do
    {:ok, {:static_dir, upload_path()}}
  end

  @impl true
  def put_file(upload) do
    {path, file} = local_path(upload.path)
    result_file = Path.join(path, file)

    unless File.exists?(result_file) do
      File.cp!(upload.tempfile, result_file)
    end

    :ok
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
