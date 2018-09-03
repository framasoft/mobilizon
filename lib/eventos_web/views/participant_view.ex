defmodule EventosWeb.ParticipantView do
  @moduledoc """
  View for Participants
  """
  use EventosWeb, :view
  alias EventosWeb.{ParticipantView, ActorView}

  def render("index.json", %{participants: participants}) do
    %{data: render_many(participants, ParticipantView, "participant.json")}
  end

  def render("show.json", %{participant: participant}) do
    %{data: render_one(participant, ParticipantView, "participant.json")}
  end

  def render("participant.json", %{participant: participant}) do
    %{
      role: participant.role,
      actor: render_one(participant.actor, ActorView, "actor_basic.json"),
    }
  end
end
