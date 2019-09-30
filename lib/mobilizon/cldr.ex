defmodule Mobilizon.Cldr do
  @moduledoc """
  Module to define supported locales
  """

  use Cldr,
    locales: ["cs", "de", "en", "es", "fr", "it", "ja", "nl", "pl", "pt", "ru"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
