# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.Fallback do
  @moduledoc """
  Module to parse fallback data in HTML pages (plain old title and meta description)
  """
  @spec parse(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def parse(html, data) do
    data =
      data
      |> maybe_put(html, :title)
      |> maybe_put(html, :description)

    if Enum.empty?(data) do
      {:error, "Not even a title"}
    else
      {:ok, data}
    end
  end

  defp maybe_put(meta, html, attr) do
    case get_page(html, attr) do
      "" -> meta
      content -> Map.put_new(meta, attr, content)
    end
  end

  defp get_page(html, :title) do
    html
    |> Floki.parse_document!()
    |> Floki.find("html title")
    |> List.first()
    |> Floki.text()
    |> String.trim()
  end

  defp get_page(html, :description) do
    case html
         |> Floki.parse_document!()
         |> Floki.find("html meta[name='description']")
         |> List.first() do
      nil -> ""
      elem -> elem |> Floki.attribute("content") |> List.first() |> String.trim()
    end
  end
end
