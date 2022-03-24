defmodule Mobilizon.GraphQL.API.Groups do
  @moduledoc """
  API for Groups.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.GraphQL.Error
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}
  alias Mobilizon.Service.Formatter.HTML
  import Mobilizon.Web.Gettext

  @doc """
  Create a group
  """
  @spec create_group(map) ::
          {:ok, Activity.t(), Actor.t()}
          | {:error, String.t() | Ecto.Changeset.t()}
  def create_group(args) do
    preferred_username =
      args |> Map.get(:preferred_username) |> HTML.strip_tags() |> String.trim()

    args = args |> Map.put(:type, :Group)

    case Actors.get_local_actor_by_name(preferred_username) do
      nil ->
        Actions.Create.create(:actor, args, true, %{"actor" => args.creator_actor.url})

      %Actor{} ->
        {:error,
         %Error{
           code: :validation,
           message: dgettext("errors", "A profile or group with that name already exists"),
           status_code: 409,
           field: "preferred_username"
         }}
    end
  end

  @spec update_group(map) ::
          {:ok, Activity.t(), Actor.t()} | {:error, :group_not_found | Ecto.Changeset.t()}
  def update_group(%{id: id} = args) do
    with {:ok, %Actor{type: :Group} = group} <- Actors.get_group_by_actor_id(id) do
      Actions.Update.update(group, args, true, %{"actor" => args.updater_actor.url})
    end
  end
end
