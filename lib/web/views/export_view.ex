defmodule Mobilizon.Web.ExportView do
  use Mobilizon.Web, :view

  alias Mobilizon.Service.Address
  alias Mobilizon.Service.DateTime, as: DateTimeRenderer
  import Mobilizon.Web.Gettext

  defdelegate datetime_to_string(datetime, locale \\ "en", format \\ :medium),
    to: DateTimeRenderer

  defdelegate datetime_to_time_string(datetime, locale \\ "en", format \\ :short),
    to: DateTimeRenderer

  defdelegate datetime_tz_convert(datetime, timezone), to: DateTimeRenderer
  defdelegate datetime_relative(datetime, locale \\ "en"), to: DateTimeRenderer
  defdelegate render_address(address), to: Address
end
