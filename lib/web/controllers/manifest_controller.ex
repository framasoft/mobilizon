defmodule Mobilizon.Web.ManifestController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Config
  alias Mobilizon.Medias.Media

  @spec manifest(Plug.Conn.t(), any) :: Plug.Conn.t()
  def manifest(conn, _params) do
    favicons =
      case Config.instance_favicon() do
        %Media{file: %{url: url}, metadata: metadata} ->
          [
            Map.merge(
              %{
                src: url
              },
              case metadata do
                %{width: width} -> %{sizes: "#{width}x#{width}"}
                _ -> %{}
              end
            )
          ]

        _ ->
          [
            %{
              src: "./img/icons/android-chrome-512x512.png",
              sizes: "512x512",
              type: "image/png"
            },
            %{
              src: "./img/icons/android-chrome-192x192.png",
              sizes: "192x192",
              type: "image/png"
            }
          ]
      end

    json(conn, %{
      name: Config.instance_name(),
      start_url: "/",
      scope: "/",
      display: "standalone",
      background_color: "#ffffff",
      theme_color: "#ffd599",
      orientation: "portrait-primary",
      icons: favicons
    })
  end

  @spec favicon(Plug.Conn.t(), any) :: Plug.Conn.t()
  def favicon(conn, _params) do
    case Config.instance_favicon() do
      %Media{file: %{url: url}} -> redirect(conn, external: url)
      _ -> redirect(conn, to: "/img/icons/favicon.ico")
    end
  end
end
