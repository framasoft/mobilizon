defmodule Mobilizon.Web.Views.Utils do
  @moduledoc """
  Utils for views
  """

  @spec get_locale(Plug.Conn.t()) :: String.t()
  def get_locale(%Plug.Conn{assigns: assigns}) do
    Map.get(assigns, :locale)
  end

  @ltr_languages ["ar", "ae", "he", "fa", "ku", "ur"]

  @spec get_language_direction(String.t()) :: String.t()
  def get_language_direction(locale) when locale in @ltr_languages, do: "rtl"
  def get_language_direction(_locale), do: "ltr"
end
