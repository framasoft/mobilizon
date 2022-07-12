defmodule Mobilizon.Service.Statistics do
  @moduledoc """
  A module that provides cached statistics
  """

  alias Mobilizon.{Actors, Discussions, Events, Users}
  alias Mobilizon.Events.Categories
  alias Mobilizon.Federation.ActivityPub.Relay

  @spec get_cached_value(String.t()) :: any() | nil
  def get_cached_value(key) do
    case Cachex.fetch(:statistics, key, fn key ->
           case create_cache(key) do
             value when not is_nil(value) -> {:commit, value}
             err -> {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> nil
    end
  end

  defp create_cache(:local_users) do
    Users.count_users()
  end

  defp create_cache(:local_events) do
    Events.count_local_events()
  end

  defp create_cache(:confirmed_participations_to_local_events) do
    Events.count_confirmed_participants_for_local_events()
  end

  defp create_cache(:local_comments) do
    Discussions.count_local_comments_under_events()
  end

  defp create_cache(:local_groups) do
    Actors.count_local_groups()
  end

  defp create_cache(:federation_events) do
    Events.count_events()
  end

  defp create_cache(:federation_comments) do
    Discussions.count_comments_under_events()
  end

  defp create_cache(:federation_groups) do
    Actors.count_groups()
  end

  defp create_cache(:instance_followers) do
    relay_actor = Relay.get_actor()
    Actors.count_followers_for_actor(relay_actor)
  end

  defp create_cache(:instance_followings) do
    relay_actor = Relay.get_actor()
    Actors.count_followings_for_actor(relay_actor)
  end

  @spec category_statistics :: list({String.t(), non_neg_integer()})
  def category_statistics do
    case Cachex.fetch(:statistics, :categories, fn ->
           allowed_categories =
             Categories.list()
             |> Enum.map(fn %{id: category} -> category |> Atom.to_string() |> String.upcase() end)

           statistics =
             Events.category_statistics()
             |> Enum.filter(fn {category, _} -> category in allowed_categories end)
             |> Enum.map(fn {category, number} -> %{key: category, number: number} end)

           {:commit, statistics}
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> nil
    end
  end
end
