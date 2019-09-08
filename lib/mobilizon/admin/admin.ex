defmodule Mobilizon.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query

  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Storage.{Page, Repo}

  @doc """
  Creates a action_log.
  """
  @spec create_action_log(map) :: {:ok, ActionLog.t()} | {:error, Ecto.Changeset.t()}
  def create_action_log(attrs \\ %{}) do
    %ActionLog{}
    |> ActionLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of action logs.
  """
  @spec list_action_logs(integer | nil, integer | nil) :: [ActionLog.t()]
  def list_action_logs(page \\ nil, limit \\ nil) do
    list_action_logs_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @spec list_action_logs_query :: Ecto.Query.t()
  defp list_action_logs_query do
    from(r in ActionLog, preload: [:actor])
  end
end
