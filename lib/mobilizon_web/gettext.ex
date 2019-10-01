defmodule MobilizonWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import MobilizonWeb.Gettext

      # Simple translation
      gettext "Here is the string to translate"

      # Plural translation
      ngettext "Here is the string to translate",
               "Here are the strings to translate",
               3

      # Domain-based translation
      dgettext "errors", "Here is the error message to translate"

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :mobilizon

  def put_locale(locale) do
    locale = determine_best_locale(locale)
    Gettext.put_locale(MobilizonWeb.Gettext, locale)
  end

  @spec determine_best_locale(String.t()) :: String.t()
  def determine_best_locale(locale) do
    locale = String.trim(locale)
    locales = Gettext.known_locales(MobilizonWeb.Gettext)

    cond do
      # Either it matches directly, eg: "en" => "en", "fr" => "fr", "fr_FR" => "fr_FR"
      locale in locales -> locale
      # Either the first part matches, "fr_CA" => "fr"
      split_locale(locale) in locales -> split_locale(locale)
      # Otherwise default to english
      true -> "en"
    end
  end

  # Keep only the first part of the locale
  defp split_locale(locale), do: locale |> String.split("_", trim: true, parts: 2) |> hd
end
