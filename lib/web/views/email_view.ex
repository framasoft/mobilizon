defmodule Mobilizon.Web.EmailView do
  use Phoenix.View,
    root: "lib/web/templates",
    pattern: "**/*",
    namespace: Mobilizon.Web

  alias Mobilizon.Service.Address
  alias Mobilizon.Service.DateTime, as: DateTimeRenderer
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Web.Gettext
  import Mobilizon.Service.Metadata.Utils, only: [process_description: 1]
  import Phoenix.HTML, only: [raw: 1]

  defdelegate datetime_to_string(datetime, locale \\ "en", format \\ :medium),
    to: DateTimeRenderer

  defdelegate datetime_to_time_string(datetime, locale \\ "en", format \\ :short),
    to: DateTimeRenderer

  defdelegate datetime_to_date_string(datetime, locale \\ "en", format \\ :short),
    to: DateTimeRenderer

  defdelegate datetime_tz_convert(datetime, timezone), to: DateTimeRenderer
  defdelegate datetime_relative(datetime, locale \\ "en"), to: DateTimeRenderer
  defdelegate render_address(address), to: Address
  defdelegate is_same_day?(one, two), to: DateTimeRenderer
end
