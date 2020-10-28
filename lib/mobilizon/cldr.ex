defmodule Mobilizon.Cldr do
  @moduledoc """
  Module to define supported locales
  """

  use Cldr,
    locales: [
      "ar",
      "be",
      "ca",
      "cs",
      "de",
      "en",
      "es",
      "fi",
      "fr",
      "gl",
      "it",
      "ja",
      "nl",
      "oc",
      "pl",
      "pt",
      "ru",
      "sv"
    ],
    gettext: Mobilizon.Web.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Language]
end
