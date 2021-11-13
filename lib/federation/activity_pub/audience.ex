defmodule Mobilizon.Federation.ActivityPub.Audience do
  @moduledoc """
  Tools for calculating content audience
  """

  alias Mobilizon.{Actors, Discussions, Events, Share}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Repo

  require Logger

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  @type audience :: %{required(String.t()) => list(String.t())}

  @doc """
  Get audience for an entity
  """
  @spec get_audience(Entity.t()) :: audience()
  def get_audience(%Event{} = event) do
    extract_actors_from_event(event)
  end

  def get_audience(%Post{draft: true} = post) do
    get_audience(%Post{post | visibility: :private, draft: false})
  end

  def get_audience(%Post{attributed_to: %Actor{} = group, visibility: visibility}) do
    {to, cc} = get_to_and_cc(group, [], visibility)
    %{"to" => to, "cc" => cc}
  end

  def get_audience(%Discussion{actor: actor}) do
    %{"to" => maybe_add_group_members([], actor), "cc" => []}
  end

  # Deleted comments are just like tombstones
  def get_audience(%Comment{deleted_at: deleted_at}) when not is_nil(deleted_at) do
    %{"to" => [@ap_public], "cc" => []}
  end

  def get_audience(%Comment{discussion: %Discussion{id: discussion_id}}) do
    discussion_id
    |> Discussions.get_discussion()
    |> get_audience()
  end

  def get_audience(%Comment{
        mentions: mentions,
        actor: %Actor{} = actor,
        visibility: visibility,
        in_reply_to_comment: in_reply_to_comment,
        event: event,
        origin_comment: origin_comment,
        url: url
      }) do
    with {to, cc} <-
           extract_actors_from_mentions(mentions, actor, visibility),
         {to, cc} <- {to ++ add_in_reply_to(in_reply_to_comment), cc},
         {to, cc} <- add_event_organizers(event, to, cc),
         {to, cc} <-
           {to,
            cc ++
              add_comments_authors([origin_comment]) ++
              add_shares_actors_followers(url)} do
      %{"to" => Enum.uniq(to), "cc" => Enum.uniq(cc)}
    end
  end

  def get_audience(%Participant{} = participant) do
    %Event{} = event = Events.get_event_with_preload!(participant.event_id)
    %Actor{} = organizer = group_or_organizer_event(event)

    cc =
      event.id
      |> Mobilizon.Events.list_actors_participants_for_event()
      |> Enum.map(& &1.url)
      |> Enum.filter(&(&1 != participant.actor.url))
      |> maybe_add_group_members(organizer)
      |> maybe_add_followers(organizer)

    %{
      "to" => [participant.actor.url, organizer.url],
      "cc" => cc
    }
  end

  def get_audience(%Member{} = member) do
    %{"to" => [member.parent.url, member.parent.members_url], "cc" => []}
  end

  def get_audience(%Actor{} = actor) do
    %{
      "to" => [@ap_public],
      "cc" =>
        maybe_add_group_members([actor.followers_url], actor) ++
          add_actors_that_had_our_content(actor.id)
    }
  end

  @spec get_to_and_cc(Actor.t(), list(), :direct | :private | :public | :unlisted | {:list, any}) ::
          {list(), list()}
  @doc """
  Determines the full audience based on mentions for an audience

  For a public audience:
    * `to` : the mentioned actors, the eventual actor we're replying to and the public
    * `cc` : the actor's followers

  For an unlisted audience:
    * `to` : the mentioned actors, actor's followers and the eventual actor we're replying to
    * `cc` : public

  For a private audience:
    * `to` : the mentioned actors, actor's followers and the eventual actor we're replying to
    * `cc` : none

  For a direct audience:
    * `to` : the mentioned actors and the eventual actor we're replying to
    * `cc` : none
  """
  def get_to_and_cc(%Actor{} = actor, mentions, :public) do
    to = [@ap_public | mentions]
    cc = [actor.followers_url]

    cc = maybe_add_group_members(cc, actor)

    {to, cc}
  end

  def get_to_and_cc(%Actor{} = actor, mentions, :unlisted) do
    to = [actor.followers_url | mentions]
    cc = [@ap_public]

    to = maybe_add_group_members(to, actor)

    {to, cc}
  end

  def get_to_and_cc(%Actor{} = actor, mentions, :private) do
    {to, cc} = get_to_and_cc(actor, mentions, :direct)

    to = maybe_add_group_members(to, actor)

    {to, cc}
  end

  def get_to_and_cc(_actor, mentions, :direct) do
    {mentions, []}
  end

  def get_to_and_cc(_actor, mentions, {:list, _}) do
    {mentions, []}
  end

  @spec maybe_add_group_members(list(String.t()), Actor.t()) :: list(String.t())
  defp maybe_add_group_members(collection, %Actor{type: :Group, members_url: members_url}) do
    [members_url | collection]
  end

  defp maybe_add_group_members(collection, %Actor{type: _}), do: collection

  @spec maybe_add_followers(list(String.t()), Actor.t()) :: list(String.t())
  defp maybe_add_followers(collection, %Actor{type: :Group, followers_url: followers_url}) do
    [followers_url | collection]
  end

  defp maybe_add_followers(collection, %Actor{type: _}), do: collection

  defp add_in_reply_to(%Comment{actor: %Actor{url: url}} = _comment), do: [url]
  defp add_in_reply_to(%Event{organizer_actor: %Actor{url: url}} = _event), do: [url]
  defp add_in_reply_to(_), do: []

  defp add_event_organizers(%Event{} = event, to, cc) do
    event = Repo.preload(event, [:organizer_actor, :attributed_to])

    case event do
      %Event{
        attributed_to: %Actor{members_url: members_url, followers_url: followers_url},
        organizer_actor: %Actor{url: organizer_actor_url}
      } ->
        {to ++ [organizer_actor_url, members_url], cc ++ [followers_url]}

      %Event{organizer_actor: %Actor{url: organizer_actor_url}} ->
        {to ++ [organizer_actor_url], cc}
    end
  end

  defp add_event_organizers(_, to, cc), do: {to, cc}

  defp add_comment_author(%Comment{} = comment) do
    case Repo.preload(comment, [:actor]) do
      %Comment{actor: %Actor{url: url}} ->
        url

      _err ->
        nil
    end
  end

  defp add_comment_author(_), do: nil

  defp add_comments_authors(comments) do
    authors =
      comments
      |> Enum.map(&add_comment_author/1)
      |> Enum.filter(& &1)

    authors
  end

  @spec add_shares_actors_followers(String.t()) :: list(String.t())
  defp add_shares_actors_followers(uri) do
    uri
    |> Share.get_actors_by_share_uri()
    |> Enum.map(& &1.url)
    |> Enum.uniq()
  end

  defp add_actors_that_had_our_content(actor_id) do
    actor_id
    |> Share.get_actors_by_owner_actor_id()
    |> Enum.map(& &1.url)
    |> Enum.uniq()
  end

  defp process_mention({_, mentioned_actor}), do: mentioned_actor.url

  defp process_mention(%{actor_id: actor_id}) do
    with %Actor{url: url} <- Actors.get_actor(actor_id) do
      url
    end
  end

  @spec extract_actors_from_mentions(list(), Actor.t(), atom()) :: {list(), list()}
  defp extract_actors_from_mentions(mentions, actor, visibility) do
    get_to_and_cc(actor, Enum.map(mentions, &process_mention/1), visibility)
  end

  @spec extract_actors_from_event(Event.t()) :: %{
          String.t() => list(String.t())
        }
  defp extract_actors_from_event(%Event{} = event) do
    {to, cc} =
      extract_actors_from_mentions(
        event.mentions,
        group_or_organizer_event(event),
        event.visibility
      )

    {to, cc} =
      {to,
       Enum.uniq(
         cc ++ add_comments_authors(event.comments) ++ add_shares_actors_followers(event.url)
       )}

    %{"to" => to, "cc" => cc}
  end

  @spec group_or_organizer_event(Event.t()) :: Actor.t()
  defp group_or_organizer_event(%Event{attributed_to: %Actor{} = group}), do: group
  defp group_or_organizer_event(%Event{organizer_actor: %Actor{} = actor}), do: actor
end
