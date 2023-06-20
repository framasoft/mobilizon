defmodule Mobilizon.Web.ExportController do
  @moduledoc """
  Controller to serve exported files
  """
  use Mobilizon.Web, :controller
  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)
  alias Mobilizon.Export
  import Mobilizon.Service.Export.Participants.Common, only: [enabled_formats: 0, export_path: 1]
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  # sobelow_skip ["Traversal.SendDownload"]
  @spec export(Plug.Conn.t(), map) :: {:error, :not_found} | Plug.Conn.t()
  def export(conn, %{"format" => format, "file" => file}) do
    if format in enabled_formats() do
      case Export.get_export(file, "event_participants", format) do
        %Export{file_name: file_name, file_path: file_path} ->
          local_path = Path.join(export_path(format), file_path)
          # We're using encode: false to disable escaping the filename with URI.encode_www_form/1
          # but it may introduce an security issue if the event title wasn't properly sanitized
          # https://github.com/phoenixframework/phoenix/pull/3344
          # https://owasp.org/www-community/attacks/HTTP_Response_Splitting
          send_download(conn, {:file, local_path}, filename: file_name, encode: false)

        nil ->
          {:error, :not_found}
      end
    else
      send_resp(
        conn,
        404,
        dgettext("errors", "Export to format %{format} is not enabled on this instance",
          format: format
        )
      )
    end
  end
end
