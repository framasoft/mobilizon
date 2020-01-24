# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/xml_builder.ex

defmodule Mobilizon.Federation.WebFinger.XmlBuilder do
  @moduledoc """
  Builds XRD for WebFinger host_meta.
  """

  def to_xml({tag, attributes, content}) do
    open_tag = make_open_tag(tag, attributes)
    content_xml = to_xml(content)

    "<#{open_tag}>#{content_xml}</#{tag}>"
  end

  def to_xml({tag, %{} = attributes}) do
    open_tag = make_open_tag(tag, attributes)

    "<#{open_tag} />"
  end

  def to_xml({tag, content}), do: to_xml({tag, %{}, content})

  def to_xml(content) when is_binary(content), do: to_string(content)

  def to_xml(content) when is_list(content) do
    content
    |> Enum.map(&to_xml/1)
    |> Enum.join()
  end

  def to_xml(%NaiveDateTime{} = time), do: NaiveDateTime.to_iso8601(time)

  def to_doc(content), do: ~s(<?xml version="1.0" encoding="UTF-8"?>) <> to_xml(content)

  defp make_open_tag(tag, attributes) do
    attributes_string =
      attributes
      |> Enum.map(fn {attribute, value} -> "#{attribute}=\"#{value}\"" end)
      |> Enum.join(" ")

    [tag, attributes_string] |> Enum.join(" ") |> String.trim()
  end
end
