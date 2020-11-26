defmodule Mobilizon.GraphQL.API.Utils do
  @moduledoc """
  Utils for API.
  """

  alias Mobilizon.{Config, Medias}
  alias Mobilizon.Medias.Media
  alias Mobilizon.Service.Formatter

  @doc """
  Creates HTML content from text and mentions
  """
  @spec make_content_html(String.t(), list(), String.t()) :: String.t()
  def make_content_html(text, additional_tags, content_type) do
    with {text, mentions, tags} <- format_input(text, content_type, []) do
      {text, mentions, additional_tags ++ Enum.map(tags, fn {_, tag} -> tag end)}
    end
  end

  def format_input(text, "text/plain", options) do
    text
    |> Formatter.html_escape("text/plain")
    |> Formatter.linkify(options)
    |> (fn {text, mentions, tags} -> {String.replace(text, ~r/\r?\n/, "<br>"), mentions, tags} end).()
  end

  def format_input(text, "text/html", options) do
    text
    |> Formatter.html_escape("text/html")
    |> Formatter.linkify(options)
  end

  def make_report_content_text(nil), do: {:ok, nil}

  def make_report_content_text(comment) do
    max_size = Config.get([:instance, :max_report_comment_size], 1000)

    if String.length(comment) <= max_size do
      {:ok, Formatter.html_escape(comment, "text/plain")}
    else
      {:error, "Comment must be up to #{max_size} characters"}
    end
  end

  @doc """
  Use the data-media-id attributes to extract media from body text
  """
  @spec extract_pictures_from_body(String.t(), integer() | String.t()) :: list(Media.t())
  def extract_pictures_from_body(body, actor_id) do
    body
    |> do_extract_pictures_from_body()
    |> Enum.map(&fetch_picture(&1, actor_id))
    |> Enum.filter(& &1)
  end

  @spec do_extract_pictures_from_body(String.t()) :: list(String.t())
  defp do_extract_pictures_from_body(body) when is_nil(body) or body == "", do: []

  defp do_extract_pictures_from_body(body) do
    {:ok, document} = Floki.parse_document(body)

    document
    |> Floki.attribute("img", "data-media-id")
  end

  @spec fetch_picture(String.t() | integer(), String.t() | integer()) :: Media.t() | nil
  defp fetch_picture(id, actor_id) do
    with %Media{actor_id: media_actor_id} = media <- Medias.get_media(id),
         {:owns_media, true} <-
           {:owns_media, check_actor_owns_media?(actor_id, media_actor_id)} do
      media
    else
      _ -> nil
    end
  end

  @spec check_actor_owns_media?(integer() | String.t(), integer() | String.t()) :: boolean()
  defp check_actor_owns_media?(actor_id, media_actor_id) do
    actor_id == media_actor_id || Mobilizon.Actors.is_member?(media_actor_id, actor_id)
  end
end
