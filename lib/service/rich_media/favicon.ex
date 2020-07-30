defmodule Mobilizon.Service.RichMedia.Favicon do
  @moduledoc """
  Module to fetch favicon information from a website

  Taken and adapted from https://github.com/ricn/favicon
  """

  require Logger
  alias Mobilizon.Config

  @options [
    max_body: 2_000_000,
    timeout: 10_000,
    recv_timeout: 20_000,
    follow_redirect: true,
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  @spec fetch(String.t(), Enum.t()) :: {:ok, String.t()} | {:error, any()}
  def fetch(url, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, Config.instance_user_agent())
    headers = [{"User-Agent", user_agent}]

    case Tesla.get(url, headers: headers, opts: @options) do
      {:ok, %{status: code, body: body}} when code in 200..299 ->
        find_favicon_url(url, body, headers)

      {:ok, %{}} ->
        {:error, "Error while fetching the page"}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec find_favicon_url(String.t(), String.t(), Enum.t()) :: {:ok, String.t()} | {:error, any()}
  defp find_favicon_url(url, body, headers) do
    Logger.debug("finding favicon URL for #{url}")

    case find_favicon_link_tag(body) do
      {:ok, tag} ->
        Logger.debug("Found link #{inspect(tag)}")
        {"link", attrs, _} = tag

        {"href", path} =
          Enum.find(attrs, fn {name, _} ->
            name == "href"
          end)

        {:ok, format_url(url, path)}

      _ ->
        find_favicon_in_root(url, headers)
    end
  end

  @spec format_url(String.t(), String.t()) :: String.t()
  defp format_url(url, path) do
    image_uri = URI.parse(path)
    uri = URI.parse(url)

    cond do
      is_nil(image_uri.host) -> "#{uri.scheme}://#{uri.host}#{path}"
      is_nil(image_uri.scheme) -> "#{uri.scheme}:#{path}"
      true -> path
    end
  end

  @spec find_favicon_link_tag(String.t()) :: {:ok, tuple()} | {:error, any()}
  defp find_favicon_link_tag(html) do
    with {:ok, html} <- Floki.parse_document(html),
         links <- Floki.find(html, "link"),
         {:link, link} when not is_nil(link) <-
           {:link,
            Enum.find(links, fn {"link", attrs, _} ->
              Enum.any?(attrs, fn {name, value} ->
                name == "rel" && String.contains?(value, "icon") &&
                  !String.contains?(value, "-icon-")
              end)
            end)} do
      {:ok, link}
    else
      {:link, nil} -> {:error, "No link found"}
      err -> err
    end
  end

  @spec find_favicon_in_root(String.t(), Enum.t()) :: {:ok, String.t()} | {:error, any()}
  defp find_favicon_in_root(url, headers) do
    uri = URI.parse(url)
    favicon_url = "#{uri.scheme}://#{uri.host}/favicon.ico"

    case Tesla.head(favicon_url, headers: headers, opts: @options) do
      {:ok, %{status: code}} when code in 200..299 ->
        {:ok, favicon_url}

      {:ok, %{}} ->
        {:error, "Error while doing a HEAD request on the favicon"}

      {:error, err} ->
        {:error, err}
    end
  end
end
