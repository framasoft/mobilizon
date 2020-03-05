defmodule Mobilizon.Federation.ActivityStream.Converter.Participant do
  @moduledoc """
  Participant converter.

  This module allows to convert reports from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Events.Participant, as: ParticipantModel

  alias Mobilizon.Federation.ActivityStream.Convertible

  defimpl Convertible, for: ParticipantModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Participant, as: ParticipantConverter

    defdelegate model_to_as(participant), to: ParticipantConverter
  end

  @doc """
  Convert an event struct to an ActivityStream representation.
  """
  @spec model_to_as(ParticipantModel.t()) :: map
  def model_to_as(%ParticipantModel{} = participant) do
    %{
      "type" => "Join",
      "id" => participant.url,
      "actor" => participant.actor.url,
      "object" => participant.event.url,
      "participationMessage" => Map.get(participant.metadata, :message)
    }
  end
end
