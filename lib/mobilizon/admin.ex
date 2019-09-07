defmodule Mobilizon.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query

  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Storage.{Page, Repo}

  @doc """
  Returns the list of action_logs.

  ## Examples

      iex> list_action_logs()
      [%ActionLog{}, ...]

  """
  @spec list_action_logs(integer(), integer()) :: list(ActionLog.t())
  def list_action_logs(page \\ nil, limit \\ nil) do
    from(
      r in ActionLog,
      preload: [:actor]
    )
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Creates a action_log.

  ## Examples

      iex> create_action_log(%{field: value})
      {:ok, %ActionLog{}}

      iex> create_action_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_action_log(attrs \\ %{}) do
    %ActionLog{}
    |> ActionLog.changeset(attrs)
    |> Repo.insert()
  end
end
