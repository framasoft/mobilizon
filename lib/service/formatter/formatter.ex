# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/formatter.ex

defmodule Mobilizon.Service.Formatter do
  @moduledoc """
  Formats input text to structured data, extracts mentions and hashtags.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Service.Formatter.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Web.Endpoint

  # https://github.com/rrrene/credo/issues/912
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @link_regex ~r"((?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~%:/?#[\]@!\$&'\(\)\*\+,;=.]+)|[0-9a-z+\-\.]+:[0-9a-z$-_.+!*'(),]+"ui
  @markdown_characters_regex ~r/(`|\*|_|{|}|[|]|\(|\)|#|\+|-|\.|!)/

  @spec escape_mention_handler(String.t(), String.t(), any(), any()) :: String.t()
  defp escape_mention_handler("@" <> nickname = mention, buffer, _, _) do
    case ActivityPubActor.find_or_make_actor_from_nickname(nickname) do
      {:ok, %Actor{}} ->
        # escape markdown characters with `\\`
        # (we don't want something like @user__name to be parsed by markdown)
        String.replace(mention, @markdown_characters_regex, "\\\\\\1")

      {:error, _err} ->
        buffer
    end
  end

  @spec mention_handler(String.t(), String.t(), any(), map()) :: {String.t(), map()}
  def mention_handler("@" <> nickname, buffer, _opts, acc) do
    case ActivityPubActor.find_or_make_actor_from_nickname(nickname) do
      #      %Actor{preferred_username: preferred_username} = actor ->
      #        link = "<span class='h-card mention'>@<span>#{preferred_username}</span></span>"
      #
      #        {link, %{acc | mentions: MapSet.put(acc.mentions, {"@" <> nickname, actor})}}

      {:ok, %Actor{type: :Person, id: id, preferred_username: preferred_username} = actor} ->
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

      # Ignore groups mentions for now
      {:ok, %Actor{type: :Group}} ->
        {buffer, acc}

      {:error, _} ->
        {buffer, acc}
    end
  end

  @spec hashtag_handler(String.t(), String.t(), any(), map()) :: {String.t(), map()}
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
    {text, %{mentions: mentions, tags: tags}} = Linkify.link_map(text, acc, options)

    {text, MapSet.to_list(mentions), MapSet.to_list(tags)}
  end

  @doc """
  Escapes a special characters in mention names.
  """
  @spec mentions_escape(String.t(), Keyword.t()) :: String.t()
  def mentions_escape(text, options \\ []) do
    options =
      Keyword.merge(options,
        mention: true,
        url: false,
        mention_handler: &escape_mention_handler/4
      )

    Linkify.link(text, options)
  end

  @spec html_escape(
          {text :: String.t(), mentions :: list(), hashtags :: list()},
          type :: String.t()
        ) :: {String.t(), list(), list()}
  @spec html_escape(text :: String.t(), type :: String.t()) :: String.t()
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

  @spec truncate(String.t(), non_neg_integer(), String.t()) :: String.t()
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

  @spec linkify_opts :: Keyword.t()
  defp linkify_opts do
    Mobilizon.Config.get(__MODULE__) ++
      [
        hashtag: true,
        hashtag_handler: &__MODULE__.hashtag_handler/4,
        mention: true,
        mention_handler: &__MODULE__.mention_handler/4
      ]
  end
end
