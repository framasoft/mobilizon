defmodule MobilizonWeb.API.Utils do
  @moduledoc """
  Utils for API
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Formatter

  @doc """
  Determines the full audience based on mentions for a public audience

  Audience is:
    * `to` : the mentionned actors, the eventual actor we're replying to and the public
    * `cc` : the actor's followers
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, inReplyTo, :public) do
    to = ["https://www.w3.org/ns/activitystreams#Public" | mentions]
    cc = [actor.followers_url]

    if inReplyTo do
      {Enum.uniq([inReplyTo.actor | to]), cc}
    else
      {to, cc}
    end
  end

  @doc """
  Determines the full audience based on mentions based on a unlisted audience

  Audience is:
    * `to` : the mentionned actors, actor's followers and the eventual actor we're replying to
    * `cc` : public
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, inReplyTo, :unlisted) do
    to = [actor.followers_url | mentions]
    cc = ["https://www.w3.org/ns/activitystreams#Public"]

    if inReplyTo do
      {Enum.uniq([inReplyTo.actor | to]), cc}
    else
      {to, cc}
    end
  end

  @doc """
  Determines the full audience based on mentions based on a private audience

  Audience is:
    * `to` : the mentionned actors, actor's followers and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, inReplyTo, :private) do
    {to, cc} = get_to_and_cc(actor, mentions, inReplyTo, :direct)
    {[actor.followers_url | to], cc}
  end

  @doc """
  Determines the full audience based on mentions based on a direct audience

  Audience is:
    * `to` : the mentionned actors and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(_actor, mentions, inReplyTo, :direct) do
    if inReplyTo do
      {Enum.uniq([inReplyTo.actor | mentions]), []}
    else
      {mentions, []}
    end
  end

  def get_to_and_cc(_user, mentions, _inReplyTo, {:list, _}), do: {mentions, []}

  #  def get_addressed_users(_, to) when is_list(to) do
  #    Actors.get(to)
  #  end

  def get_addressed_users(mentioned_users, _), do: mentioned_users

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

  #  @doc """
  #  Formatting text to markdown.
  #  """
  #  def format_input(text, "text/markdown", options) do
  #    text
  #    |> Formatter.mentions_escape(options)
  #    |> Earmark.as_html!()
  #    |> Formatter.linkify(options)
  #    |> Formatter.html_escape("text/html")
  #  end

  def make_report_content_html(nil), do: {:ok, {nil, [], []}}

  def make_report_content_html(comment) do
    max_size = Mobilizon.CommonConfig.get([:instance, :max_report_comment_size], 1000)

    if String.length(comment) <= max_size do
      {:ok, Formatter.html_escape(comment, "text/plain")}
    else
      {:error, "Comment must be up to #{max_size} characters"}
    end
  end

  def prepare_content(actor, content, visibility, tags, in_reply_to) do
    with content <- String.trim(content),
         {content_html, mentions, tags} <-
           make_content_html(
             content,
             tags,
             "text/plain"
           ),
         mentioned_users <- for({_, mentioned_user} <- mentions, do: mentioned_user.url),
         addressed_users <- get_addressed_users(mentioned_users, nil),
         {to, cc} <- get_to_and_cc(actor, addressed_users, in_reply_to, visibility) do
      {content_html, tags, to, cc}
    end
  end
end
