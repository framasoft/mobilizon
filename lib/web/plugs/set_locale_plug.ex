# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

# NOTE: this module is based on https://github.com/smeevil/set_locale
defmodule Mobilizon.Web.Plugs.SetLocalePlug do
  @moduledoc """
  Plug to set locale for Gettext
  """
  import Plug.Conn, only: [get_req_header: 2, assign: 3]

  def init(_), do: nil

  def call(conn, _) do
    locale = get_locale_from_header(conn) || Gettext.get_locale()
    Gettext.put_locale(locale)
    assign(conn, :locale, locale)
  end

  defp get_locale_from_header(conn) do
    conn
    |> extract_accept_language()
    |> Enum.find(&supported_locale?/1)
  end

  defp extract_accept_language(conn) do
    case get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(& &1.tag)
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()

      _ ->
        []
    end
  end

  defp supported_locale?(locale) do
    Mobilizon.Web.Gettext
    |> Gettext.known_locales()
    |> Enum.member?(locale)
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        :error -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map(tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end)
  end
end
