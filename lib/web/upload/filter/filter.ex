# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/upload/filter.ex

defmodule Mobilizon.Web.Upload.Filter do
  @moduledoc """
  Upload Filter behaviour

  This behaviour allows to run filtering actions just before a file is uploaded. This allows to:

    * morph in place the temporary file
    * change any field of a `Mobilizon.Upload` struct
    * cancel/stop the upload
  """

  require Logger

  @callback filter(Mobilizon.Web.Upload.t()) ::
              {:ok, :filtered}
              | {:ok, :noop}
              | {:ok, :filtered, Mobilizon.Web.Upload.t()}
              | {:error, any()}

  @spec filter([module()], Mobilizon.Web.Upload.t()) ::
          {:ok, Mobilizon.Web.Upload.t()} | {:error, any()}

  def filter([], upload) do
    {:ok, upload}
  end

  def filter([filter | rest], upload) do
    case filter.filter(upload) do
      {:ok, :filtered} ->
        filter(rest, upload)

      {:ok, :filtered, upload} ->
        filter(rest, upload)

      {:ok, :noop} ->
        filter(rest, upload)

      error ->
        Logger.error("#{__MODULE__}: Filter #{filter} failed: #{inspect(error)}")
        error
    end
  end
end
