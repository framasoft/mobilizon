defmodule Mobilizon.Cldr do
  @moduledoc """
  Module to define supported locales
  """

  use Cldr,
    locales: Application.get_env(:mobilizon, :cldr)[:locales],
    gettext:
      if(Application.fetch_env!(:mobilizon, :env) == :prod,
        do: Mobilizon.Web.Gettext,
        else: nil
      ),
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Language]
end
