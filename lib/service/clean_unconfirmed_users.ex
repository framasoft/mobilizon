defmodule Mobilizon.Service.CleanUnconfirmedUsers do
  @moduledoc """
  Service to clean unconfirmed users
  """

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User
  import Ecto.Query

  @grace_period Mobilizon.Config.get([:instance, :unconfirmed_user_grace_period_hours], 48)

  @doc """
  Clean unattached media

  Remove media that is not attached to an entity, such as media uploads that were never used in entities.
  """
  @spec clean(Keyword.t()) :: {:ok, list(Media.t())} | {:error, String.t()}
  def clean(opts \\ []) do
    users_to_delete = find_unconfirmed_users_to_clean(opts)

    if Keyword.get(opts, :dry_run, false) do
      {:ok, users_to_delete}
    else
      users_to_delete = Enum.map(users_to_delete, &delete_user/1)

      {:ok, users_to_delete}
    end
  end

  @spec delete_user(User.t()) :: {:ok, User.t()}
  defp delete_user(%User{} = user) do
    with actors <- Users.get_actors_for_user(user),
         :ok <-
           Enum.each(actors, fn actor ->
             actor_performing = Relay.get_actor()

             Actors.perform(:delete_actor, actor,
               author_id: actor_performing.id,
               reserve_username: false
             )
           end),
         {:ok, %User{} = user} <- Users.delete_user(user, reserve_email: false),
         %User{} = user <- %User{user | actors: actors} do
      user
    end
  end

  @spec find_unconfirmed_users_to_clean(Keyword.t()) :: list(User.t())
  defp find_unconfirmed_users_to_clean(opts) do
    grace_period = Keyword.get(opts, :grace_period, @grace_period)
    expiration_date = DateTime.add(DateTime.utc_now(), grace_period * -3600)

    User
    |> where([u], is_nil(u.confirmed_at) and u.confirmation_sent_at < ^expiration_date)
    |> Repo.all()
  end
end
