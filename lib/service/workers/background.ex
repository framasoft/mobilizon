defmodule Mobilizon.Service.Workers.Background do
  @moduledoc """
  Worker to perform various actions in the background
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  use Mobilizon.Service.Workers.Helper, queue: "background"

  @impl Oban.Worker
  def perform(%Job{args: %{"op" => "delete_actor", "actor_id" => actor_id} = args}) do
    with reserve_username when is_boolean(reserve_username) <-
           Map.get(args, "reserve_username", true),
         %Actor{} = actor <- Actors.get_actor(actor_id) do
      Actors.perform(:delete_actor, actor, reserve_username: reserve_username)
    end
  end

  def perform(%Job{args: %{"op" => "actor_key_rotation", "actor_id" => actor_id}}) do
    with %Actor{} = actor <- Actors.get_actor(actor_id) do
      Actors.actor_key_rotation(actor)
    end
  end
end
