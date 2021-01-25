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

  @twitter_card_properties [
    :card,
    :site,
    :creator,
    :title,
    :description,
    :image,
    :"image:alt"
  ]

  @spec parse(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def parse(html, data) do
    Logger.debug("Using Twitter card parser")

    with {:ok, data} <- parse_name_attrs(data, html),
         {:ok, data} <- parse_property_attrs(data, html),
         data <- transform_tags(data) do
      Logger.debug("Data found with Twitter card parser")
      Logger.debug(inspect(data))
      data
    end
  end

  defp parse_name_attrs(data, html) do
    MetaTagsParser.parse(html, data, "twitter", %{}, :name, :content, [:"twitter:card"])
  end

  defp parse_property_attrs({_, data}, html) do
    MetaTagsParser.parse(
      html,
      data,
      "twitter",
      "No twitter card metadata found",
      :property,
      :content,
      @twitter_card_properties
    )
  end

  defp transform_tags(data) do
    data
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.update(:image_remote_url, Map.get(data, :image), & &1)
  end
end
