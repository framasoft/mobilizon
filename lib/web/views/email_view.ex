defmodule Mobilizon.Web.EmailView do
  use Mobilizon.Web, :view

  import Mobilizon.Web.Gettext

  def datetime_to_string(%DateTime{} = datetime, locale \\ "en") do
    with {:ok, string} <-
           Cldr.DateTime.to_string(datetime, Mobilizon.Cldr, format: :medium, locale: locale) do
      string
    end
  end
end
