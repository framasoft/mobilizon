defmodule Mobilizon.Actors.Service.Tools do
  @moduledoc """
  Common functions for actors services
  """
  alias Mobilizon.Actors.User

  @spec we_can_send_email(User.t(), atom()) :: :ok | {:error, :email_too_soon}
  def we_can_send_email(%User{} = user, key \\ :reset_password_sent_at) do
    case Map.get(user, key) do
      nil ->
        :ok

      _ ->
        case Timex.before?(
               Timex.shift(Map.get(user, key), hours: 1),
               DateTime.utc_now() |> DateTime.truncate(:second)
             ) do
          true ->
            :ok

          false ->
            {:error, :email_too_soon}
        end
    end
  end

  @spec random_string(integer) :: String.t()
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end
end
