defmodule Mix.Tasks.Mobilizon.Actors.Utils do
  @moduledoc """
  Tools for generating usernames from display names
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @doc """
  Removes all spaces, accents, special characters and diacritics from a string to create a plain ascii username (a-z0-9_)

  See https://stackoverflow.com/a/37511463
  """
  @spec generate_username(String.t()) :: String.t()
  def generate_username(""), do: ""

  def generate_username(name) do
    name
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[\x{0300}-\x{036f}]/u, "")
    |> String.replace(~r/ /, "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
  end

  # Profile from name
  @spec username_and_name(String.t() | nil, String.t() | nil) :: String.t()
  def username_and_name(nil, profile_name) do
    {generate_username(profile_name), profile_name}
  end

  def username_and_name(profile_username, nil) do
    {profile_username, profile_username}
  end

  def username_and_name(profile_username, profile_name) do
    {profile_username, profile_name}
  end

  def create_profile(%User{id: user_id}, username, name, options \\ []) do
    {username, name} = username_and_name(username, name)

    {:ok, %Actor{} = new_person} =
      Actors.new_person(
        %{preferred_username: username, user_id: user_id, name: name},
        Keyword.get(options, :default, true)
      )

    new_person
  end

  def create_group(%Actor{id: admin_id}, username, name, _options \\ []) do
    {username, name} = username_and_name(username, name)

    Actors.create_group(%{creator_actor_id: admin_id, preferred_username: username, name: name})
  end
end
