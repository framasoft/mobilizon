defmodule Mix.Tasks.Mobilizon.SiteMap do
  @moduledoc """
  Task to generate a new Sitemap
  """
  use Mix.Task

  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Service.SiteMap
  alias Mobilizon.Web.Endpoint

  @preferred_cli_env "prod"

  @shortdoc "Generates a new Sitemap"
  def run(["generate"]) do
    start_mobilizon()

    with {:ok, :ok} <- SiteMap.generate_sitemap() do
      shell_info("Sitemap saved to #{Endpoint.url()}/sitemap.xml")
    end
  end
end
