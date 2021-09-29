# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

# NOTE: this module is based on https://github.com/smeevil/set_locale
defmodule Mobilizon.Web.Plugs.SetLocalePlug do
  @moduledoc """
  Plug to set locale for Gettext
  """
  import Plug.Conn, only: [assign: 3]
  alias Mobilizon.Web.Gettext, as: GettextBackend

  @spec init(any()) :: nil
  def init(_), do: nil

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _) do
    locale =
      [
        conn.assigns[:user_locale],
        conn.assigns[:detected_locale],
        default_locale(),
        "en"
      ]
      |> Enum.map(&determine_best_locale/1)
      |> Enum.filter(&supported_locale?/1)
      |> hd()

    Gettext.put_locale(locale)
    assign(conn, :locale, locale)
  end

  @spec supported_locale?(String.t()) :: boolean()
  defp supported_locale?(locale) do
    GettextBackend
    |> Gettext.known_locales()
    |> Enum.member?(locale)
  end

  @spec default_locale :: String.t()
  defp default_locale do
    Keyword.get(Mobilizon.Config.instance_config(), :default_language, "en")
  end

  @doc """
  Determine the best available locale for a given locale ID
  """
  @spec determine_best_locale(String.t()) :: String.t() | nil
  def determine_best_locale(locale) when is_binary(locale) do
    locale = String.trim(locale)
    locales = Gettext.known_locales(GettextBackend)

    cond do
      locale == "" -> nil
      # Either it matches directly, eg: "en" => "en", "fr" => "fr"
      locale in locales -> locale
      # Either the first part matches, "fr_CA" => "fr"
      split_locale(locale) in locales -> split_locale(locale)
      # Otherwise set to default
      true -> nil
    end
  end

  def determine_best_locale(_), do: nil

  # Keep only the first part of the locale
  @spec split_locale(String.t()) :: String.t()
  defp split_locale(locale), do: locale |> String.split("_", trim: true, parts: 2) |> hd
end
