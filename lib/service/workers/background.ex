defmodule Mobilizon.Service.Workers.Background do
  @moduledoc """
  Worker to build search results
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  use Mobilizon.Service.Workers.Helper, queue: "background"

  @impl Oban.Worker
  def perform(%{"op" => "delete_actor", "actor_id" => actor_id}, _job) do
    with %Actor{} = actor <- Actors.get_actor(actor_id) do
      Actors.perform(:delete_actor, actor)
    end
  end
end
