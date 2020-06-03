# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.TwitterCard do
  @moduledoc """
  Module to parse Twitter tags data in HTML pages
  """
  alias Mobilizon.Service.RichMedia.Parsers.MetaTagsParser
  require Logger

  @spec parse(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def parse(html, data) do
    Logger.debug("Using Twitter card parser")

    res =
      data
      |> parse_name_attrs(html)
      |> parse_property_attrs(html)

    Logger.debug("Data found with Twitter card parser")
    Logger.debug(inspect(res))
    res
  end

  defp parse_name_attrs(data, html) do
    MetaTagsParser.parse(html, data, "twitter", %{}, "name")
  end

  defp parse_property_attrs({_, data}, html) do
    MetaTagsParser.parse(html, data, "twitter", "No twitter card metadata found", "property")
  end
end
