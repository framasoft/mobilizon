# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.MetaTagsParser do
  @moduledoc """
  Module to parse meta tags data in HTML pages
  """

  def parse(
        html,
        data,
        prefix,
        error_message,
        key_name,
        value_name \\ :content,
        allowed_attributes \\ []
      ) do
    meta_data =
      html
      |> get_elements(key_name, prefix)
      |> Enum.reduce(data, fn el, acc ->
        attributes = normalize_attributes(el, prefix, key_name, value_name, allowed_attributes)

        Map.merge(acc, attributes)
      end)
      |> maybe_put_title(html)
      |> maybe_put_description(html)

    if Enum.empty?(meta_data) do
      {:error, error_message}
    else
      {:ok, meta_data}
    end
  end

  defp get_elements(html, key_name, prefix) do
    html |> Floki.find("meta[#{to_string(key_name)}^='#{prefix}:']")
  end

  defp normalize_attributes(html_node, prefix, key_name, value_name, allowed_attributes) do
    {_tag, attributes, _children} = html_node

    data =
      attributes
      |> Enum.into(%{}, fn {name, value} ->
        {name, String.trim_leading(value, "#{prefix}:")}
      end)

    if data[to_string(key_name)] in Enum.map(allowed_attributes, &to_string/1) do
      %{String.to_existing_atom(data[to_string(key_name)]) => data[to_string(value_name)]}
    else
      %{}
    end
  end

  defp maybe_put_title(%{title: _} = meta, _), do: meta

  defp maybe_put_title(meta, html) when meta != %{} do
    case get_page_title(html) do
      "" -> meta
      title -> Map.put_new(meta, :title, title)
    end
  end

  defp maybe_put_title(meta, _), do: meta

  defp maybe_put_description(%{description: _} = meta, _), do: meta

  defp maybe_put_description(meta, html) when meta != %{} do
    case get_page_description(html) do
      "" -> meta
      description -> Map.put_new(meta, :description, description)
    end
  end

  defp maybe_put_description(meta, _), do: meta

  defp get_page_title(html) do
    html |> Floki.find("html head title") |> List.first() |> Floki.text()
  end

  defp get_page_description(html) do
    case html |> Floki.find("html head meta[name='description']") |> List.first() do
      nil -> ""
      elem -> Floki.attribute(elem, "content")
    end
  end
end
