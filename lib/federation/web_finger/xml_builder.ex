# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/xml_builder.ex

defmodule Mobilizon.Federation.WebFinger.XmlBuilder do
  @moduledoc """
  Extremely basic XML encoder. Builds XRD for WebFinger host_meta.
  """

  @typep content :: list({tag :: atom(), attributes :: map()}) | String.t()
  @typep document :: {tag :: atom(), attributes :: map(), content :: content}

  @doc """
  Return the XML representation for a document.
  """
  @spec to_doc(document :: document) :: String.t()
  def to_doc(document), do: ~s(<?xml version="1.0" encoding="UTF-8"?>) <> to_xml(document)

  @spec to_xml(document) :: String.t()
  @spec to_xml({tag :: atom(), attributes :: map()}) :: String.t()
  @spec to_xml({tag :: atom(), content :: content}) :: String.t()
  @spec to_xml(content :: content) :: String.t()
  defp to_xml({tag, attributes, content}) do
    open_tag = make_open_tag(tag, attributes)
    content_xml = to_xml(content)

    "<#{open_tag}>#{content_xml}</#{tag}>"
  end

  defp to_xml({tag, %{} = attributes}) do
    open_tag = make_open_tag(tag, attributes)

    "<#{open_tag} />"
  end

  defp to_xml({tag, content}), do: to_xml({tag, %{}, content})

  defp to_xml(content) when is_binary(content), do: to_string(content)

  defp to_xml(content) when is_list(content) do
    Enum.map_join(content, &to_xml/1)
  end

  defp to_xml(%NaiveDateTime{} = time), do: NaiveDateTime.to_iso8601(time)

  @spec make_open_tag(tag :: atom, attributes :: map()) :: String.t()
  defp make_open_tag(tag, attributes) do
    attributes_string =
      Enum.map_join(attributes, " ", fn {attribute, value} -> "#{attribute}=\"#{value}\"" end)

    [to_string(tag), attributes_string] |> Enum.join(" ") |> String.trim()
  end
end
