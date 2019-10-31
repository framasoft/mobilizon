defmodule Mobilizon.Service.ActivityPub.Audience do
  @moduledoc """
  Tools for calculating content audience
  """
  alias Mobilizon.Actors.Actor

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  @doc """
  Determines the full audience based on mentions for a public audience

  Audience is:
    * `to` : the mentioned actors, the eventual actor we're replying to and the public
    * `cc` : the actor's followers
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, in_reply_to, :public) do
    to = [@ap_public | mentions]
    cc = [actor.followers_url]

    if in_reply_to do
      {Enum.uniq([in_reply_to.actor | to]), cc}
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
  def get_to_and_cc(%Actor{} = actor, mentions, in_reply_to, :unlisted) do
    to = [actor.followers_url | mentions]
    cc = [@ap_public]

    if in_reply_to do
      {Enum.uniq([in_reply_to.actor | to]), cc}
    else
      {to, cc}
    end
  end

  @doc """
  Determines the full audience based on mentions based on a private audience

  Audience is:
    * `to` : the mentioned actors, actor's followers and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, in_reply_to, :private) do
    {to, cc} = get_to_and_cc(actor, mentions, in_reply_to, :direct)
    {[actor.followers_url | to], cc}
  end

  @doc """
  Determines the full audience based on mentions based on a direct audience

  Audience is:
    * `to` : the mentioned actors and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), map(), String.t()) :: {list(), list()}
  def get_to_and_cc(_actor, mentions, in_reply_to, :direct) do
    if in_reply_to do
      {Enum.uniq([in_reply_to.actor | mentions]), []}
    else
      {mentions, []}
    end
  end

  def get_to_and_cc(_actor, mentions, _in_reply_to, {:list, _}) do
    {mentions, []}
  end

  #  def get_addressed_actors(_, to) when is_list(to) do
  #    Actors.get(to)
  #  end

  def get_addressed_actors(mentioned_users, _), do: mentioned_users

  def calculate_to_and_cc_from_mentions(
        actor,
        mentions \\ [],
        in_reply_to \\ nil,
        visibility \\ :public
      ) do
    with mentioned_actors <- for({_, mentioned_actor} <- mentions, do: mentioned_actor.url),
         addressed_actors <- get_addressed_actors(mentioned_actors, nil),
         {to, cc} <- get_to_and_cc(actor, addressed_actors, in_reply_to, visibility) do
      %{"to" => to, "cc" => cc}
    end
  end
end
