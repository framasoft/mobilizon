defmodule Mobilizon.Web.PageView do
  @moduledoc """
  View for our webapp
  """

  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Tombstone

  alias Mobilizon.Service.Metadata
  alias Mobilizon.Service.Metadata.Instance

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.Convertible
  import Mobilizon.Web.Views.Utils

  @doc false
  @spec render(String.t(), %{conn: Plug.Conn.t()}) :: map() | String.t() | Plug.Conn.t()
  def render("actor.activity-json", %{conn: %{assigns: %{object: %Actor{} = actor}}}) do
    actor
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Event{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Tombstone{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("comment.activity-json", %{conn: %{assigns: %{object: %Comment{} = comment}}}) do
    comment
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("discussion.activity-json", %{conn: %{assigns: %{object: %Discussion{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resource.activity-json", %{conn: %{assigns: %{object: %Resource{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("post.activity-json", %{conn: %{assigns: %{object: %Post{} = post}}}) do
    post
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render(page, %{object: object, conn: conn} = assigns)
      when page in ["actor.html", "event.html", "comment.html", "post.html"] do
    with locale <- get_locale(conn),
         tags <- object |> Metadata.build_tags(locale),
         assigns <- Map.put(assigns, :tags, tags) do
      render("index.html", assigns)
    end
  end

  # Discussions are private, no need to embed metadata
  def render("discussion.html", params), do: render("index.html", params)

  def tags(assigns) do
    Map.get(assigns, :tags, Instance.build_tags())
  end

  def theme_color do
    "#ffd599"
  end

  def language_direction(assigns) do
    assigns |> Map.get(:locale, "en") |> get_language_direction()
  end

  @spec root?(map()) :: boolean()
  def root?(assigns) do
    assigns |> Map.get(:conn, %{request_path: "/"}) |> Map.get(:request_path, "/") == "/"
  end

  defp favicon do
    case Config.instance_favicon() do
      %{file: %{url: url}, metadata: metadata} ->
        %{
          src: url,
          sizes:
            case metadata do
              %{width: width} -> "#{width}x#{width}"
              _ -> "any"
            end
        }

      _ ->
        %{
          src: "/img/icons/apple-touch-icon-152x152.png",
          sizes: "152x152"
        }
    end
  end

  def favicon_url, do: Map.get(favicon(), :src)
  def favicon_sizes, do: Map.get(favicon(), :sizes)
end
