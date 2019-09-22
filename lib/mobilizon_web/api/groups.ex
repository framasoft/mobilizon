defmodule MobilizonWeb.API.Groups do
  @moduledoc """
  API for Groups.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias Mobilizon.Users.User

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
          avatar: _avatar,
          banner: _banner
        } = args
      ) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, creator_actor_id),
         title <- String.trim(title),
         {:existing_group, nil} <- {:existing_group, Actors.get_group_by_title(title)},
         visibility <- Map.get(args, :visibility, :public),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(actor, summary, visibility, [], nil),
         group <- ActivityPubUtils.make_group_data(actor.url, to, title, content_html, tags, cc) do
      ActivityPub.create(%{
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        actor: actor,
        object: group,
        local: true
      })
    else
      {:existing_group, _} ->
        {:error, "A group with this name already exists"}

      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end
end
