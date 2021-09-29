defmodule Mobilizon.Service.Workers.Background do
  @moduledoc """
  Worker to perform various actions in the background
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Refresher
  alias Mobilizon.Service.ActorSuspension

  use Mobilizon.Service.Workers.Helper, queue: "background"

  @impl Oban.Worker
  @spec perform(Job.t()) ::
          {:ok, Actor.t()}
          | {:error,
             :actor_not_found | :bad_option_value_for_reserve_username | Ecto.Changeset.t()}
  def perform(%Job{args: %{"op" => "delete_actor", "actor_id" => actor_id} = args}) do
    case Map.get(args, "reserve_username", true) do
      reserve_username when is_boolean(reserve_username) ->
        case Actors.get_actor(actor_id) do
          %Actor{} = actor ->
            ActorSuspension.suspend_actor(actor, reserve_username: reserve_username)

          nil ->
            {:error, :actor_not_found}
        end

      _ ->
        {:error, :bad_option_value_for_reserve_username}
    end
  end

  def perform(%Job{args: %{"op" => "actor_key_rotation", "actor_id" => actor_id}}) do
    with %Actor{} = actor <- Actors.get_actor(actor_id) do
      Actors.actor_key_rotation(actor)
    end
  end

  def perform(%Job{args: %{"op" => "refresh_profile", "actor_id" => actor_id}}) do
    with %Actor{} = actor <- Actors.get_actor(actor_id) do
      Refresher.refresh_profile(actor)
    end
  end
end
