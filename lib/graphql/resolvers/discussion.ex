defmodule Mobilizon.GraphQL.Resolvers.Discussion do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Discussions}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.GraphQL.API.Comments
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  @spec find_discussions_for_actor(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Discussion.t())} | {:error, :unauthenticated}
  def find_discussions_for_actor(
        %Actor{id: group_id},
        %{page: page, limit: limit},
        %{
          context: %{
            current_actor: %Actor{id: actor_id}
          }
        }
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         {:ok, %Actor{type: :Group} = group} <- Actors.get_group_by_actor_id(group_id) do
      {:ok, Discussions.find_discussions_for_actor(group, page, limit)}
    else
      {:member, false} ->
        {:ok, %Page{total: 0, elements: []}}
    end
  end

  def find_discussions_for_actor(%Actor{}, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  @spec get_discussion(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Discussion.t()} | {:error, :unauthorized | :discussion_not_found | String.t()}
  def get_discussion(_parent, %{id: id}, %{
        context: %{
          current_actor: %Actor{id: creator_id}
        }
      }) do
    case Discussions.get_discussion(id) do
      %Discussion{actor_id: actor_id} = discussion ->
        if Actors.member?(creator_id, actor_id) do
          {:ok, discussion}
        else
          {:error, :unauthorized}
        end

      nil ->
        {:error, :discussion_not_found}
    end
  end

  def get_discussion(_parent, %{slug: slug}, %{
        context: %{
          current_actor: %Actor{id: creator_id}
        }
      }) do
    with %Discussion{actor_id: actor_id} = discussion <-
           Discussions.get_discussion_by_slug(slug),
         {:member, true} <- {:member, Actors.member?(creator_id, actor_id)} do
      {:ok, discussion}
    else
      nil -> {:error, dgettext("errors", "Discussion not found")}
      {:member, false} -> {:error, :unauthorized}
    end
  end

  def get_discussion(_parent, _args, %{
        context: %{
          current_user: %User{} = _user
        }
      }),
      do:
        {:error,
         dgettext("errors", "You must provide either an ID or a slug to access a discussion")}

  def get_discussion(_parent, _args, _resolution),
    do: {:error, dgettext("errors", "You need to be logged-in to access discussions")}

  @spec get_comments_for_discussion(Discussion.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Discussion.t())}
  def get_comments_for_discussion(
        %Discussion{id: discussion_id},
        %{page: page, limit: limit},
        _resolution
      ) do
    {:ok, Discussions.get_comments_for_discussion(discussion_id, page, limit)}
  end

  @spec create_discussion(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Discussion.t()}
          | {:error, Ecto.Changeset.t() | String.t() | :unauthorized | :unauthenticated}
  def create_discussion(
        _parent,
        %{title: title, text: text, actor_id: group_id},
        %{
          context: %{
            current_actor: %Actor{id: creator_id}
          }
        }
      ) do
    if Actors.member?(creator_id, group_id) do
      case Comments.create_discussion(%{
             title: title,
             text: text,
             actor_id: group_id,
             creator_id: creator_id,
             attributed_to_id: group_id
           }) do
        {:ok, _activity, %Discussion{} = discussion} ->
          {:ok, discussion}

        {:error, %Ecto.Changeset{} = err} ->
          {:error, err}

        {:error, _err} ->
          {:error, dgettext("errors", "Error while creating a discussion")}
      end
    else
      {:error, :unauthorized}
    end
  end

  def create_discussion(_, _, _), do: {:error, :unauthenticated}

  @spec reply_to_discussion(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Discussion.t()} | {:error, :discussion_not_found | :unauthenticated}
  def reply_to_discussion(
        _parent,
        %{text: text, discussion_id: discussion_id},
        %{
          context: %{
            current_actor: %Actor{id: creator_id}
          }
        }
      ) do
    with {:no_discussion,
          %Discussion{
            actor_id: actor_id,
            last_comment: %Comment{
              id: last_comment_id,
              origin_comment_id: origin_comment_id,
              in_reply_to_comment_id: previous_in_reply_to_comment_id
            }
          } = _discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           Comments.create_discussion(%{
             text: text,
             discussion_id: discussion_id,
             actor_id: creator_id,
             attributed_to_id: actor_id,
             in_reply_to_comment_id: last_comment_id,
             origin_comment_id:
               origin_comment_id || previous_in_reply_to_comment_id || last_comment_id
           }) do
      {:ok, discussion}
    else
      {:no_discussion, _} ->
        {:error, :discussion_not_found}
    end
  end

  def reply_to_discussion(_, _, _), do: {:error, :unauthenticated}

  @spec update_discussion(map(), map(), map()) ::
          {:ok, Discussion.t()} | {:error, :unauthorized | :unauthenticated}
  def update_discussion(
        _parent,
        %{title: title, discussion_id: discussion_id},
        %{
          context: %{
            current_actor: %Actor{id: creator_id}
          }
        }
      ) do
    with {:no_discussion, %Discussion{actor_id: actor_id} = discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           Actions.Update.update(
             discussion,
             %{
               title: title
             }
           ) do
      {:ok, discussion}
    else
      {:member, false} ->
        {:error, :unauthorized}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  def update_discussion(_, _, _), do: {:error, :unauthenticated}

  @spec delete_discussion(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Discussion.t()} | {:error, String.t() | :unauthorized | :unauthenticated}
  def delete_discussion(_parent, %{discussion_id: discussion_id}, %{
        context: %{
          current_user: %User{},
          current_actor: %Actor{id: creator_id} = actor
        }
      }) do
    with {:no_discussion, %Discussion{actor_id: actor_id} = discussion} <-
           {:no_discussion, Discussions.get_discussion(discussion_id)},
         {:member, true} <- {:member, Actors.member?(creator_id, actor_id)},
         {:ok, _activity, %Discussion{} = discussion} <-
           Actions.Delete.delete(discussion, actor) do
      {:ok, discussion}
    else
      {:no_discussion, _} ->
        {:error, dgettext("errors", "No discussion with ID %{id}", id: discussion_id)}

      {:member, _} ->
        {:error, :unauthorized}
    end
  end

  def delete_discussion(_, _, _), do: {:error, :unauthenticated}
end
