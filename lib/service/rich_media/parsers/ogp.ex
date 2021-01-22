# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.OGP do
  @moduledoc """
  Module to parse OpenGraph data in HTML pages
  """
  require Logger
  alias Mobilizon.Service.RichMedia.Parsers.MetaTagsParser

  @opengraph_properties [
    :title,
    :type,
    :image,
    :url,
    :audio,
    :description,
    :determiner,
    :locale,
    :"locale:alternate",
    :site_name,
    :video,
    :"image:url",
    :"image.secure_url",
    :"image:type",
    :"image:width",
    :"image:height",
    :"image:alt"
  ]

  def parse(html, data) do
    Logger.debug("Using OpenGraph card parser")

    with {:ok, data} <-
           MetaTagsParser.parse(
             html,
             data,
             "og",
             "No OGP metadata found",
             :property,
             :content,
             @opengraph_properties
           ) do
      data = transform_tags(data)
      Logger.debug("Data found with OpenGraph card parser")
      {:ok, data}
    end
  end

  defp transform_tags(data) do
    data
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.update(:image_remote_url, Map.get(data, :image), & &1)
    |> Map.update(:width, get_integer_value(data, :"image:width"), & &1)
    |> Map.update(:height, get_integer_value(data, :"image:height"), & &1)
  end

  @spec get_integer_value(map(), atom()) :: integer() | nil
  defp get_integer_value(data, key) do
    with value when not is_nil(value) <- Map.get(data, key),
         {value, ""} <- Integer.parse(value) do
      value
    else
      _ -> nil
    end
  end
end
