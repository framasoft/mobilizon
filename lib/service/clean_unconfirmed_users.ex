defmodule Mobilizon.Service.CleanUnconfirmedUsers do
  @moduledoc """
  Service to clean unconfirmed users
  """

  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.ActorSuspension
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import Ecto.Query

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

  @spec delete_user(User.t()) :: User.t() | {:error, Ecto.Changeset.t()} | no_return
  defp delete_user(%User{} = user) do
    actors = Users.get_actors_for_user(user)
    %{id: actor_performing_id} = Relay.get_actor()

    Enum.each(actors, fn actor ->
      ActorSuspension.suspend_actor(actor,
        author_id: actor_performing_id,
        reserve_username: false
      )
    end)

    case Users.delete_user(user, reserve_email: false) do
      {:ok, %User{} = user} ->
        %User{user | actors: actors}
    end
  end

  @spec find_unconfirmed_users_to_clean(Keyword.t()) :: list(User.t())
  defp find_unconfirmed_users_to_clean(opts) do
    default_grace_period =
      Mobilizon.Config.get([:instance, :unconfirmed_user_grace_period_hours], 48)

    grace_period = Keyword.get(opts, :grace_period, default_grace_period)
    expiration_date = DateTime.add(DateTime.utc_now(), grace_period * -3600)

    User
    |> where([u], is_nil(u.confirmed_at) and u.confirmation_sent_at < ^expiration_date)
    |> Repo.all()
  end
end
