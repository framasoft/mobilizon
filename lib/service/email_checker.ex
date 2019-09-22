defmodule Mobilizon.Service.EmailChecker do
  @moduledoc """
  Provides a function to test emails against a "not so bad" regex.
  """

  # TODO: simplify me!
  @email_regex ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

  @doc """
  Returns whether the email is valid.
  """
  @spec valid?(String.t()) :: boolean
  def valid?(email), do: email =~ @email_regex
end
