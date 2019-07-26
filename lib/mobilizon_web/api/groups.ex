defmodule MobilizonWeb.API.Groups do
  @moduledoc """
  API for Events
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils, as: ActivityPubUtils
  alias MobilizonWeb.API.Utils

  @doc """
  Create a group
  """
  @spec create_group(map()) :: {:ok, Activity.t()} | any()
  def create_group(
        %{
          preferred_username: title,
          description: description,
          admin_actor_username: admin_actor_username
        } = args
      ) do
    with {:bad_actor, %Actor{url: url} = actor} <-
           {:bad_actor, Actors.get_local_actor_by_name(admin_actor_username)},
         {:existing_group, nil} <- {:existing_group, Actors.get_group_by_title(title)},
         title <- String.trim(title),
         visibility <- Map.get(args, :visibility, :public),
         {content_html, tags, to, cc} <-
           Utils.prepare_content(actor, description, visibility, [], nil),
         group <-
           ActivityPubUtils.make_group_data(
             url,
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
        {:error, :existing_group_name}

      {:bad_actor, _} ->
        {:error, :bad_admin_actor}
    end
  end
end
