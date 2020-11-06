defmodule Mobilizon.Cldr do
  @moduledoc """
  Module to define supported locales
  """

  use Cldr,
    locales: Application.get_env(:mobilizon, :cldr)[:locales],
    gettext: Mobilizon.Web.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Language]
end
