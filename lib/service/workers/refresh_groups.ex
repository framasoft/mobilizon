defmodule Mobilizon.Service.Workers.RefreshGroups do
  @moduledoc """
  Worker to build sitemap
  """

  alias Mobilizon.Federation.ActivityPub.Refresher

  use Oban.Worker, queue: "background"

  @impl Oban.Worker
  def perform(%Job{}), do: Refresher.refresh_all_external_groups()
end
