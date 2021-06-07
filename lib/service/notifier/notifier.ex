defmodule Mobilizon.Service.Notifier do
  @moduledoc """
  Behaviour for notifiers
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Config
  alias Mobilizon.Users.User

  @doc """
  Whether the notifier is enabled and configured
  """
  @callback ready?() :: boolean()

  @doc """
  Sends one or multiple notifications from an activity
  """
  @callback send(User.t(), Activity.t(), Keyword.t()) :: {:ok, any()} | {:error, String.t()}

  @callback send(User.t(), list(Activity.t()), Keyword.t()) :: {:ok, any()} | {:error, String.t()}

  def notify(%User{} = user, %Activity{} = activity, opts \\ []) do
    Enum.each(providers(opts), & &1.send(user, activity, opts))
  end

  @spec providers(Keyword.t()) :: list()
  defp providers(opts) do
    opts
    |> Keyword.get(:notifiers, Config.get([__MODULE__, :notifiers]))
    |> Enum.filter(& &1.ready?())
  end
end
