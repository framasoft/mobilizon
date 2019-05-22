# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/uploaders/local.ex

defmodule MobilizonWeb.Uploaders.Local do
  @moduledoc """
  Local uploader for files
  """
  @behaviour MobilizonWeb.Uploaders.Uploader

  def get_file(_) do
    {:ok, {:static_dir, upload_path()}}
  end

  def put_file(upload) do
    {local_path, file} =
      case Enum.reverse(String.split(upload.path, "/", trim: true)) do
        [file] ->
          {upload_path(), file}

        [file | folders] ->
          path = Path.join([upload_path()] ++ Enum.reverse(folders))
          File.mkdir_p!(path)
          {path, file}
      end

    result_file = Path.join(local_path, file)

    unless File.exists?(result_file) do
      File.cp!(upload.tempfile, result_file)
    end

    :ok
  end

  def upload_path do
    Mobilizon.CommonConfig.get!([__MODULE__, :uploads])
  end
end
