defmodule Mobilizon.Federation.ActivityStream.Converter.Follower do
  @moduledoc """
  Participant converter.

  This module allows to convert followers from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors.Follower, as: FollowerModel

  alias Mobilizon.Federation.ActivityStream.Convertible

  defimpl Convertible, for: FollowerModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Follower,
      as: FollowerConverter

    defdelegate model_to_as(follower), to: FollowerConverter
  end

  @doc """
  Convert an follow struct to an ActivityStream representation.
  """
  @spec model_to_as(FollowerModel.t()) :: map
  def model_to_as(
        %FollowerModel{actor: %Actor{} = actor, target_actor: %Actor{} = target_actor} = follower
      ) do
    %{
      "type" => "Follow",
      "actor" => actor.url,
      "to" => [target_actor.url],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
      "object" => target_actor.url,
      "id" => follower.url
    }
  end
end
