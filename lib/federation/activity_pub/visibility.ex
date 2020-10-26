# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/visibility.ex

defmodule Mobilizon.Federation.ActivityPub.Visibility do
  @moduledoc """
  Utility functions related to content visibility
  """

  alias Mobilizon.Discussions.Comment

  alias Mobilizon.Federation.ActivityPub.Activity

  @public "https://www.w3.org/ns/activitystreams#Public"

  @spec is_public?(Activity.t() | map()) :: boolean()
  def is_public?(%{data: %{"type" => "Tombstone"}}), do: false
  def is_public?(%{data: data}), do: is_public?(data)
  def is_public?(%Activity{data: data}), do: is_public?(data)

  def is_public?(data) when is_map(data) do
    @public in (make_list(Map.get(data, "to", [])) ++ make_list(Map.get(data, "cc", [])))
  end

  def is_public?(%Comment{deleted_at: deleted_at}), do: !is_nil(deleted_at)
  def is_public?(err), do: raise(ArgumentError, message: "Invalid argument #{inspect(err)}")

  defp make_list(data) when is_list(data), do: data
  defp make_list(data), do: [data]
end
