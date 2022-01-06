defmodule Mobilizon.Service.Workers.CleanUnconfirmedUsersWorker do
  @moduledoc """
  Worker to clean unattached media
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Service.CleanUnconfirmedUsers

  @impl Oban.Worker
  def perform(%Job{}) do
    remove_unconfirmed_users =
      :mobilizon
      |> Application.get_env(:instance)
      |> Keyword.get(:remove_unconfirmed_users, false)

    if remove_unconfirmed_users and should_perform?() do
      CleanUnconfirmedUsers.clean()
    end
  end

  @spec should_perform? :: boolean()
  defp should_perform? do
    case Cachex.get(:key_value, "unconfirmed_users_cleanup") do
      {:ok, %DateTime{} = unconfirmed_users_cleanup} ->
        default_grace_period =
          Mobilizon.Config.get([:instance, :unconfirmed_user_grace_period_hours], 48)

        DateTime.compare(
          unconfirmed_users_cleanup,
          DateTime.add(DateTime.utc_now(), default_grace_period * -3600)
        ) == :lt

      _ ->
        true
    end
  end
end
