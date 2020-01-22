defmodule MobilizonWeb.API.Groups do
  @moduledoc """
  API for Groups.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity

  @doc """
  Create a group
  """
  @spec create_group(map()) :: {:ok, Activity.t(), Actor.t()} | any()
  def create_group(args) do
    with preferred_username <-
           args |> Map.get(:preferred_username) |> HtmlSanitizeEx.strip_tags() |> String.trim(),
         {:existing_group, nil} <-
           {:existing_group, Actors.get_local_group_by_title(preferred_username)},
         {:ok, %Activity{} = activity, %Actor{} = group} <-
           ActivityPub.create(:group, args, true, %{"actor" => args.creator_actor.url}) do
      {:ok, activity, group}
    else
      {:existing_group, _} ->
        {:error, "A group with this name already exists"}

      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}
    end
  end
end
