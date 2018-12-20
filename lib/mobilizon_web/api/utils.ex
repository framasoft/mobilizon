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
  @spec to_for_actor_and_mentions(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def to_for_actor_and_mentions(%Actor{} = actor, mentions, inReplyTo, "public") do
    mentioned_actors = Enum.map(mentions, fn {_, %{url: url}} -> url end)

    to = ["https://www.w3.org/ns/activitystreams#Public" | mentioned_actors]
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
  @spec to_for_actor_and_mentions(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def to_for_actor_and_mentions(%Actor{} = actor, mentions, inReplyTo, "unlisted") do
    mentioned_actors = Enum.map(mentions, fn {_, %{url: url}} -> url end)

    to = [actor.followers_url | mentioned_actors]
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
  @spec to_for_actor_and_mentions(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def to_for_actor_and_mentions(%Actor{} = actor, mentions, inReplyTo, "private") do
    {to, cc} = to_for_actor_and_mentions(actor, mentions, inReplyTo, "direct")
    {[actor.followers_url | to], cc}
  end

  @doc """
  Determines the full audience based on mentions based on a direct audience

  Audience is:
    * `to` : the mentionned actors and the eventual actor we're replying to
    * `cc` : none
  """
  @spec to_for_actor_and_mentions(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def to_for_actor_and_mentions(_actor, mentions, inReplyTo, "direct") do
    mentioned_actors = Enum.map(mentions, fn {_, %{url: url}} -> url end)

    if inReplyTo do
      {Enum.uniq([inReplyTo.actor | mentioned_actors]), []}
    else
      {mentioned_actors, []}
    end
  end

  @doc """
  Creates HTML content from text and mentions
  """
  @spec make_content_html(String.t(), list(), list(), String.t()) :: String.t()
  def make_content_html(
        status,
        mentions,
        tags,
        content_type
      ),
      do: format_input(status, mentions, tags, content_type)

  def format_input(text, mentions, tags, "text/plain") do
    text
    |> Formatter.html_escape("text/plain")
    |> String.replace(~r/\r?\n/, "<br>")
    |> (&{[], &1}).()
    |> Formatter.add_links()
    |> Formatter.add_actor_links(mentions)
    |> Formatter.add_hashtag_links(tags)
    |> Formatter.finalize()
  end

  def format_input(text, mentions, _tags, "text/html") do
    text
    |> Formatter.html_escape("text/html")
    |> String.replace(~r/\r?\n/, "<br>")
    |> (&{[], &1}).()
    |> Formatter.add_actor_links(mentions)
    |> Formatter.finalize()
  end

  # def format_input(text, mentions, tags, "text/markdown") do
  #   text
  #   |> Earmark.as_html!()
  #   |> Formatter.html_escape("text/html")
  #   |> String.replace(~r/\r?\n/, "")
  #   |> (&{[], &1}).()
  #   |> Formatter.add_actor_links(mentions)
  #   |> Formatter.add_hashtag_links(tags)
  #   |> Formatter.finalize()
  # end
end
