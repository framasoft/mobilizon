defmodule MobilizonWeb.API.Groups do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Actors
  alias Mobilizon.Users.User
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias MobilizonWeb.API.Utils

  @doc """
  Create a group
  """
  @spec create_group(User.t(), map()) :: {:ok, Activity.t(), Group.t()} | any()
  def create_group(
        user,
        %{
          preferred_username: title,
          summary: summary,
          creator_actor_id: creator_actor_id,
          avatar: avatar,
          banner: banner
        } = args
      ) do
    with {:is_owned, true, actor} <- User.owns_actor(user, creator_actor_id),
         {:existing_group, nil} <- {:existing_group, Actors.get_group_by_title(title)},
         title <- String.trim(title),
         visibility <- Map.get(args, :visibility, :public),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(actor, summary, visibility, [], nil),
         group <-
           ActivityPubUtils.make_group_data(
             actor.url,
             to,
             title,
             content_html,
             tags,
             cc
           ) do
      ActivityPub.create(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: actor,
        object: group,
        local: true
      })
    else
      {:existing_group, _} ->
        {:error, "A group with this name already exists"}

      {:is_owned, _} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end
end
