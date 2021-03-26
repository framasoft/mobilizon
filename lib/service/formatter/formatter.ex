# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/formatter.ex

defmodule Mobilizon.Service.Formatter do
  @moduledoc """
  Formats input text to structured data, extracts mentions and hashtags.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Formatter.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Web.Endpoint

  @link_regex ~r"((?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~%:/?#[\]@!\$&'\(\)\*\+,;=.]+)|[0-9a-z+\-\.]+:[0-9a-z$-_.+!*'(),]+"ui
  @markdown_characters_regex ~r/(`|\*|_|{|}|[|]|\(|\)|#|\+|-|\.|!)/

  def escape_mention_handler("@" <> nickname = mention, buffer, _, _) do
    case Actors.get_actor_by_name(nickname) do
      %Actor{} ->
        # escape markdown characters with `\\`
        # (we don't want something like @user__name to be parsed by markdown)
        String.replace(mention, @markdown_characters_regex, "\\\\\\1")

      _ ->
        buffer
    end
  end

  def mention_handler("@" <> nickname, buffer, _opts, acc) do
    case Actors.get_actor_by_name(nickname) do
      #      %Actor{preferred_username: preferred_username} = actor ->
      #        link = "<span class='h-card mention'>@<span>#{preferred_username}</span></span>"
      #
      #        {link, %{acc | mentions: MapSet.put(acc.mentions, {"@" <> nickname, actor})}}

      %Actor{type: :Person, id: id, preferred_username: preferred_username} = actor ->
        # link =
        #   "<span class='h-card mention' data-user='#{id}'>@<span>#{preferred_username}</span></span>"

        link =
          Tag.content_tag(
            :span,
            [
              "@",
              Tag.content_tag(
                :span,
                preferred_username
              )
            ],
            "data-user": id,
            class: "h-card mention"
          )
          |> Phoenix.HTML.safe_to_string()

        {link, %{acc | mentions: MapSet.put(acc.mentions, {"@" <> nickname, actor})}}

      _ ->
        {buffer, acc}
    end
  end

  def hashtag_handler("#" <> tag = tag_text, _buffer, _opts, acc) do
    tag = String.downcase(tag)
    url = "#{Endpoint.url()}/tag/#{tag}"

    link =
      Tag.content_tag(:a, tag_text,
        class: "hashtag",
        "data-tag": tag,
        href: url,
        rel: "tag ugc"
      )
      |> Phoenix.HTML.safe_to_string()

    {link, %{acc | tags: MapSet.put(acc.tags, {tag_text, tag})}}
  end

  @doc """
  Parses a text and replace plain text links with HTML. Returns a tuple with a result text, mentions, and hashtags.

  """
  @spec linkify(String.t(), keyword()) ::
          {String.t(), [{String.t(), Actor.t()}], [{String.t(), String.t()}]}
  def linkify(text, options \\ []) do
    options = linkify_opts() ++ options

    acc = %{mentions: MapSet.new(), tags: MapSet.new()}
    {text, %{mentions: mentions}} = Linkify.link_map(text, acc, options)
    {text, tags} = extract_tags(text)

    {text, MapSet.to_list(mentions), MapSet.to_list(tags)}
  end

  @doc """
  Escapes a special characters in mention names.
  """
  def mentions_escape(text, options \\ []) do
    options =
      Keyword.merge(options,
        mention: true,
        url: false,
        mention_handler: &escape_mention_handler/4
      )

    Linkify.link(text, options)
  end

  def html_escape({text, mentions, hashtags}, type) do
    {html_escape(text, type), mentions, hashtags}
  end

  def html_escape(text, "text/html") do
    with {:ok, content} <- HTML.filter_tags(text) do
      content
    end
  end

  def html_escape(text, "text/plain") do
    @link_regex
    |> Regex.split(text, include_captures: true)
    |> Enum.map_every(2, fn chunk ->
      {:safe, part} = Phoenix.HTML.html_escape(chunk)
      part
    end)
    |> Enum.join("")
  end

  def truncate(text, max_length \\ 200, omission \\ "...") do
    # Remove trailing whitespace
    text = Regex.replace(~r/([^ \t\r\n])([ \t]+$)/u, text, "\\g{1}")

    if String.length(text) < max_length do
      text
    else
      length_with_omission = max_length - String.length(omission)
      String.slice(text, 0, length_with_omission) <> omission
    end
  end

  defp linkify_opts do
    Mobilizon.Config.get(__MODULE__) ++
      [
        hashtag: false,
        mention: true,
        mention_handler: &__MODULE__.mention_handler/4
      ]
  end

  @match_hashtag ~r/(?:^|[^\p{L}\p{M}\p{Nd}\)])(?<tag>\#[[:word:]_]*[[:alpha:]_·][[:word:]_·\p{M}]*)/u

  @spec extract_tags(String.t()) :: {String.t(), MapSet.t()}
  def extract_tags(text) do
    matches =
      @match_hashtag
      |> Regex.scan(text, capture: [:tag])
      |> Enum.map(&hd/1)
      |> Enum.map(&{&1, tag_text_strip(&1)})
      |> MapSet.new()

    text =
      @match_hashtag
      |> Regex.replace(text, &generate_tag_link/2)
      |> String.trim()

    {text, matches}
  end

  @spec generate_tag_link(String.t(), String.t()) :: String.t()
  defp generate_tag_link(_, tag_text) do
    tag = tag_text_strip(tag_text)
    url = "#{Endpoint.url()}/tag/#{tag}"

    Tag.content_tag(:a, tag_text,
      class: "hashtag",
      "data-tag": tag,
      href: url,
      rel: "tag ugc"
    )
    |> Phoenix.HTML.safe_to_string()
    |> (&" #{&1}").()
  end

  defp tag_text_strip(tag), do: tag |> String.trim("#") |> String.downcase()
end
