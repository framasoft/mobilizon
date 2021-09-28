defmodule Mobilizon.Federation.ActivityPub.Actions.Flag do
  @moduledoc """
  Delete things
  """
  alias Mobilizon.Users
  alias Mobilizon.Federation.ActivityPub.{Activity, Types}
  alias Mobilizon.Web.Email.{Admin, Mailer}
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1
    ]

  @spec flag(map, boolean, map) :: {:ok, Activity.t(), Report.t()} | {:error, Ecto.Changeset.t()}
  def flag(args, local \\ false, additional \\ %{}) do
    with {:ok, report, report_as_data} <- Types.Reports.flag(args, local, additional) do
      {:ok, activity} = create_activity(report_as_data, local)
      maybe_federate(activity)

      Enum.each(Users.list_moderators(), fn moderator ->
        moderator
        |> Admin.report(report)
        |> Mailer.send_email_later()
      end)

      {:ok, activity, report}
    end
  end
end
