defmodule Mobilizon.Service.ActivityPub.Converters.Participant do
  @moduledoc """
  Flag converter

  This module allows to convert reports from ActivityStream format to our own internal one, and back.

  Note: Reports are named Flag in AS.
  """
  alias Mobilizon.Events.Participant, as: ParticipantModel

  @doc """
  Convert an event struct to an ActivityStream representation
  """
  @spec model_to_as(ParticipantModel.t()) :: map()
  def model_to_as(%ParticipantModel{} = participant) do
    %{
      "type" => "Join",
      "id" => participant.url,
      "actor" => participant.actor.url,
      "object" => participant.event.url
    }
  end

  defimpl Mobilizon.Service.ActivityPub.Convertible, for: Mobilizon.Events.Participant do
    alias Mobilizon.Service.ActivityPub.Converters.Participant, as: ParticipantConverter

    defdelegate model_to_as(event), to: ParticipantConverter
  end
end
