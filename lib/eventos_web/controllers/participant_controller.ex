defmodule EventosWeb.ParticipantController do
  @moduledoc """
  Controller for participants to an event
  """
  use EventosWeb, :controller

  alias Eventos.Events

  def join(conn, %{"uuid" => uuid}) do
    with event <- Events.get_event_by_uuid(uuid),
         %{actor: actor} <- Guardian.Plug.current_resource(conn) do
      participant =
        Events.create_participant(%{"event_id" => event.id, "actor_id" => actor.id, "role" => 1})

      render(conn, "participant.json", %{participant: participant})
    end
  end
end
