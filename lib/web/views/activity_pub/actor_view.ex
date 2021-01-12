defmodule Mobilizon.Web.ActivityPub.ActorView do
  use Mobilizon.Web, :view

  alias Mobilizon.{Actors, Discussions, Events, Posts, Resources, Todos}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Discussions.Discussion
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Storage.Page
  alias Mobilizon.Todos.TodoList

  @private_visibility_empty_collection %{elements: [], total: 0}
  @json_ld_header Utils.make_json_ld_header()
  @selected_member_roles ~w(creator administrator moderator member)a

  def render("actor.json", %{actor: actor}) do
    actor
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("member.json", %{member: %Member{} = member}) do
    member
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  @doc """
  Render an actor collection
  """
  @spec render(String.t(), map()) :: map()
  def render(view_name, %{actor: %Actor{} = actor} = args) do
    is_root? = is_nil(Map.get(args, :page))
    page = Map.get(args, :page, 1)
    collection_name = String.trim_trailing(view_name, ".json")
    collection_name = String.to_existing_atom(collection_name)

    %{total: total, elements: elements} =
      if can_get_collection?(collection_name, actor, Map.get(args, :actor_applicant)),
        do: fetch_collection(collection_name, actor, page),
        else: default_collection(collection_name, actor, page)

    collection =
      if is_root? do
        root_collection(elements, actor, collection_name, total)
      else
        collection(elements, actor.preferred_username, collection_name, page, total)
      end

    Map.merge(collection, @json_ld_header)
  end

  @spec root_collection(Enum.t(), Actor.t(), atom(), integer()) :: map()
  defp root_collection(
         elements,
         %Actor{preferred_username: preferred_username, url: actor_url},
         collection,
         total
       ) do
    %{
      "id" => Actor.build_url(preferred_username, collection),
      "attributedTo" => actor_url,
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(elements, preferred_username, collection, 1, total)
    }
  end

  @spec fetch_collection(atom(), Actor.t(), integer()) :: Page.t()
  defp fetch_collection(:following, actor, page) do
    Actors.build_followings_for_actor(actor, page)
  end

  defp fetch_collection(:followers, actor, page) do
    Actors.build_followers_for_actor(actor, page)
  end

  defp fetch_collection(:members, actor, page) do
    Actors.list_members_for_group(actor, @selected_member_roles, page)
  end

  defp fetch_collection(:resources, actor, page) do
    Resources.get_resources_for_group(actor, page)
  end

  defp fetch_collection(:discussions, actor, page) do
    Discussions.find_discussions_for_actor(actor, page)
  end

  defp fetch_collection(:posts, actor, page) do
    Posts.get_posts_for_group(actor, page)
  end

  defp fetch_collection(:events, actor, page) do
    Events.list_simple_organized_events_for_group(actor, page)
  end

  defp fetch_collection(:todos, actor, page) do
    Todos.get_todo_lists_for_group(actor, page)
  end

  @spec fetch_collection(atom(), Actor.t(), integer()) :: %{total: integer(), elements: Enum.t()}
  defp fetch_collection(:outbox, actor, page) do
    ActivityPub.fetch_public_activities_for_actor(actor, page)
  end

  defp fetch_collection(_, _, _), do: @private_visibility_empty_collection

  @spec can_get_collection?(atom(), Actor.t(), Actor.t()) :: boolean()
  # Outbox only contains public activities
  defp can_get_collection?(collection, %Actor{visibility: visibility} = _actor, _actor_applicant)
       when visibility in [:public, :unlisted] and collection in [:outbox, :followers, :following],
       do: true

  defp can_get_collection?(_collection_name, %Actor{} = actor, %Actor{} = actor_applicant),
    do: actor_applicant_group_member?(actor, actor_applicant)

  defp can_get_collection?(_, _, _), do: false

  # Posts and events allows to browse public content
  defp default_collection(:posts, %Actor{} = actor, page),
    do: Posts.get_public_posts_for_group(actor, page)

  defp default_collection(:events, %Actor{} = actor, page),
    do: Events.list_public_events_for_actor(actor, page)

  defp default_collection(_, _, _), do: @private_visibility_empty_collection

  @spec collection(list(), String.t(), atom(), integer(), integer()) :: map()
  defp collection(collection, preferred_username, endpoint, page, total)
       when endpoint in [
              :followers,
              :following,
              :outbox,
              :members,
              :resources,
              :todos,
              :posts,
              :events,
              :discussions
            ] do
    offset = (page - 1) * 10

    map = %{
      "id" => Actor.build_url(preferred_username, endpoint, page: page),
      "attributedTo" => Actor.build_url(preferred_username, :page),
      "type" => "OrderedCollectionPage",
      "partOf" => Actor.build_url(preferred_username, endpoint),
      "orderedItems" => Enum.map(collection, &item/1)
    }

    map =
      if offset < total do
        Map.put(map, "next", Actor.build_url(preferred_username, endpoint, page: page + 1))
      else
        map
      end

    map =
      if offset > total do
        Map.put(map, "prev", Actor.build_url(preferred_username, endpoint, page: page - 1))
      else
        map
      end

    map
  end

  def item(%Activity{data: data}), do: data
  def item(%Actor{url: url}), do: url
  def item(%Member{} = member), do: Convertible.model_to_as(member)
  def item(%Resource{} = resource), do: Convertible.model_to_as(resource)
  def item(%Discussion{} = discussion), do: Convertible.model_to_as(discussion)
  def item(%Post{} = post), do: Convertible.model_to_as(post)
  def item(%Event{} = event), do: Convertible.model_to_as(event)
  def item(%TodoList{} = todo_list), do: Convertible.model_to_as(todo_list)

  defp actor_applicant_group_member?(%Actor{}, nil), do: false

  defp actor_applicant_group_member?(%Actor{id: group_id}, %Actor{id: actor_applicant_id}),
    do:
      Actors.get_member(actor_applicant_id, group_id, [
        :member,
        :moderator,
        :administrator,
        :creator
      ]) != {:error, :member_not_found}
end
