defmodule Mobilizon.Service.Workers.BuildSiteMap do
  @moduledoc """
  Worker to build sitemap
  """

  alias Mobilizon.Service.SiteMap

  use Oban.Worker, queue: "background"

  @impl Oban.Worker
  def perform(%Job{}), do: SiteMap.generate_sitemap()
end
