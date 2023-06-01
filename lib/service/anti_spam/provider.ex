defmodule Mobilizon.Service.AntiSpam.Provider do
  @moduledoc """
  Provider Behaviour for anti-spam detection.

  ## Supported backends

    * `Mobilizon.Service.AntiSpam.Akismet` [🔗](https://akismet.com/)

  """

  @type spam_result :: :ham | :spam | :discard
  @type result :: spam_result() | {:error, any()}

  @doc """
  Make sure the provider is ready
  """
  @callback ready?() :: boolean()

  @doc """
  Check an user details
  """
  @callback check_user(email :: String.t(), ip :: String.t(), user_agent :: String.t()) ::
              result()

  @doc """
  Check a profile details
  """
  @callback check_profile(
              username :: String.t(),
              summary :: String.t(),
              email :: String.t() | nil,
              ip :: String.t(),
              user_agent :: String.t() | nil
            ) :: result()

  @doc """
  Check an event details
  """
  @callback check_event(
              event_body :: String.t(),
              username :: String.t(),
              email :: String.t() | nil,
              ip :: String.t(),
              user_agent :: String.t() | nil
            ) :: result()

  @doc """
  Check a comment details
  """
  @callback check_comment(
              comment_body :: String.t(),
              username :: String.t(),
              is_reply? :: boolean(),
              email :: String.t() | nil,
              ip :: String.t(),
              user_agent :: String.t() | nil
            ) :: result()
end
