defmodule Mobilizon.Federation.ActivityStream.Converter.Member do
  @moduledoc """
  Member converter.

  This module allows to convert members from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors.Member, as: MemberModel
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Utils

  alias Mobilizon.Federation.ActivityStream.Convertible

  defimpl Convertible, for: MemberModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Member, as: MemberConverter

    defdelegate model_to_as(member), to: MemberConverter
  end

  @doc """
  Convert an member struct to an ActivityStream representation.
  """
  @spec model_to_as(MemberModel.t()) :: map
  def model_to_as(%MemberModel{} = member) do
    %{
      "type" => "Member",
      "id" => member.url,
      "actor" => member.actor.url,
      "object" => member.parent.url,
      "role" => to_string(member.role)
    }
  end

  def as_to_model_data(%{
        "type" => "Member",
        "actor" => actor,
        "object" => group,
        "role" => role,
        "id" => url
      }) do
    with {:ok, %Actor{id: group_id}} <- get_actor(group),
         {:ok, %Actor{id: actor_id}} <- get_actor(actor) do
      %{
        url: url,
        actor_id: actor_id,
        parent_id: group_id,
        role: role
      }
    end
  end

  @spec get_actor(String.t() | map() | nil) :: {:ok, Actor.t()} | {:error, String.t()}
  defp get_actor(nil), do: {:error, "nil property found for actor data"}
  defp get_actor(actor), do: actor |> Utils.get_url() |> ActivityPub.get_or_fetch_actor_by_url()
end
