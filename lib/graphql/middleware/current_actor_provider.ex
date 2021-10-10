defmodule Mobilizon.GraphQL.Middleware.CurrentActorProvider do
  @moduledoc """
  Absinthe Error Handler
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  @spec call(Absinthe.Resolution.t(), any) :: Absinthe.Resolution.t()
  def call(
        %Absinthe.Resolution{context: %{current_user: %User{id: user_id} = user} = context} =
          resolution,
        _config
      ) do
    case Cachex.fetch(:default_actors, to_string(user_id), fn -> default(user) end) do
      {status, %Actor{preferred_username: preferred_username} = current_actor}
      when status in [:ok, :commit] ->
        Sentry.Context.set_user_context(%{name: preferred_username})
        context = Map.put(context, :current_actor, current_actor)
        %Absinthe.Resolution{resolution | context: context}

      {_, nil} ->
        resolution
    end
  end

  def call(%Absinthe.Resolution{} = resolution, _config), do: resolution

  @spec default(User.t()) :: {:commit, Actor.t()} | {:ignore, nil}
  defp default(%User{} = user) do
    case Users.get_actor_for_user(user) do
      %Actor{} = actor ->
        {:commit, actor}

      nil ->
        {:ignore, nil}
    end
  end
end
