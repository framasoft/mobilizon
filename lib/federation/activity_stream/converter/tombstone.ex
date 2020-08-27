defmodule Mobilizon.Federation.ActivityStream.Converter.Tombstone do
  @moduledoc """
  Comment converter.

  This module allows to convert Tombstone models to ActivityStreams data
  """

  alias Mobilizon.Tombstone, as: TombstoneModel

  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}

  require Logger

  @behaviour Converter

  defimpl Convertible, for: TombstoneModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Tombstone, as: TombstoneConverter

    defdelegate model_to_as(comment), to: TombstoneConverter
  end

  @doc """
  Make an AS tombstone object from an existing `Tombstone` structure.
  """
  @impl Converter
  @spec model_to_as(TombstoneModel.t()) :: map
  def model_to_as(%TombstoneModel{} = tombstone) do
    %{
      "type" => "Tombstone",
      "id" => tombstone.uri,
      "actor" => if(tombstone.actor, do: tombstone.actor.url, else: nil),
      "deleted" => tombstone.inserted_at
    }
  end

  @doc """
  Converting an Tombstone to an object makes no sense, nevertheless…
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(object), do: object
end
