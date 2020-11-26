defmodule Mobilizon.Service.Workers.CleanUnconfirmedUsersWorker do
  @moduledoc """
  Worker to clean unattached media
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Service.CleanUnconfirmedUsers

  @grace_period Mobilizon.Config.get([:instance, :unconfirmed_user_grace_period_hours], 48)

  @impl Oban.Worker
  def perform(%Job{}) do
    if Mobilizon.Config.get!([:instance, :remove_unconfirmed_users]) and should_perform?() do
      CleanUnconfirmedUsers.clean()
    end
  end

  @spec should_perform? :: boolean()
  defp should_perform? do
    case Cachex.get(:key_value, "last_media_cleanup") do
      {:ok, %DateTime{} = last_media_cleanup} ->
        DateTime.compare(
          last_media_cleanup,
          DateTime.add(DateTime.utc_now(), @grace_period * -3600)
        ) == :lt

      _ ->
        true
    end
  end
end
