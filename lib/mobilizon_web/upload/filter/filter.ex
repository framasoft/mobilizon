# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload/filter.ex

defmodule MobilizonWeb.Upload.Filter do
  @moduledoc """
  Upload Filter behaviour

  This behaviour allows to run filtering actions just before a file is uploaded. This allows to:

  * morph in place the temporary file
  * change any field of a `Mobilizon.Upload` struct
  * cancel/stop the upload
  """

  require Logger

  @callback filter(MobilizonWeb.Upload.t()) ::
              :ok | {:ok, MobilizonWeb.Upload.t()} | {:error, any()}

  @spec filter([module()], MobilizonWeb.Upload.t()) ::
          {:ok, MobilizonWeb.Upload.t()} | {:error, any()}

  def filter([], upload) do
    {:ok, upload}
  end

  def filter([filter | rest], upload) do
    case filter.filter(upload) do
      :ok ->
        filter(rest, upload)

      {:ok, upload} ->
        filter(rest, upload)

      error ->
        Logger.error("#{__MODULE__}: Filter #{filter} failed: #{inspect(error)}")
        error
    end
  end
end
