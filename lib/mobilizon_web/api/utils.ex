defmodule MobilizonWeb.API.Utils do
  @moduledoc """
  Utils for API.
  """

  alias Mobilizon.Config
  alias Mobilizon.Service.Formatter

  @doc """
  Creates HTML content from text and mentions
  """
  @spec make_content_html(String.t(), list(), String.t()) :: String.t()
  def make_content_html(
        text,
        additional_tags,
        content_type
      ) do
    with {text, mentions, tags} <- format_input(text, content_type, []) do
      {text, mentions, additional_tags ++ Enum.map(tags, fn {_, tag} -> tag end)}
    end
  end

  def format_input(text, "text/plain", options) do
    text
    |> Formatter.html_escape("text/plain")
    |> Formatter.linkify(options)
    |> (fn {text, mentions, tags} ->
          {String.replace(text, ~r/\r?\n/, "<br>"), mentions, tags}
        end).()
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
end
